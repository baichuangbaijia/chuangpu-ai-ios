package com.chuangpu.ai.ui.home

import android.animation.ValueAnimator
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.Dispatchers
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.FragmentHomeBinding
import com.chuangpu.ai.ui.chat.ChatActivity
import com.chuangpu.ai.ui.vip.VipActivity
import com.chuangpu.ai.ui.sidebar.SidebarDrawer
import com.chuangpu.ai.ui.task.TaskListActivity
import com.chuangpu.ai.util.PreferencesManager
import com.google.android.material.bottomsheet.BottomSheetDialog

class HomeFragment : Fragment() {

    private var _binding: FragmentHomeBinding? = null
    private val binding get() = _binding!!
    private lateinit var prefs: PreferencesManager
    private lateinit var apiService: com.chuangpu.ai.network.ApiService
    private var currentModel = "deepseek-v3"
    private val availableModels = listOf(
        ModelItem("deepseek-v3", "DeepSeek V3", true),
        ModelItem("kimi-2.5", "Kimi 2.5", false),
        ModelItem("glm-5", "GLM-5", false),
        ModelItem("minimax-m2.5", "MiniMax M2.5", false),
        ModelItem("doubao-2.0", "豆包 2.0", false)
    )
    data class ModelItem(val id: String, val name: String, val available: Boolean)
    private var btnGlowAnim: ValueAnimator? = null

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentHomeBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        prefs = PreferencesManager.getInstance(requireContext())
        apiService = com.chuangpu.ai.network.ApiService(requireContext())
        currentModel = prefs.getCurrentModel()
        setupLobsterWebView()
        setupUI()
        startBtnGlow()
    }

    private fun setupLobsterWebView() {
        val webView = binding.lobsterEmoji
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.setLayerType(View.LAYER_TYPE_HARDWARE, null)
        webView.setBackgroundColor(0x00000000)
        webView.webViewClient = WebViewClient()
        // 禁止WebView滚动
        webView.setOnTouchListener { _, event -> event.action == MotionEvent.ACTION_MOVE }
        webView.isVerticalScrollBarEnabled = false
        webView.isHorizontalScrollBarEnabled = false
        webView.loadUrl("file:///android_asset/lobster_anim.html")
    }

    private fun setupUI() {
        binding.btnMenu.setOnClickListener { toggleSidebar() }
        binding.btnStart.setOnClickListener { startChat() }
        binding.btnSend.setOnClickListener {
            val text = binding.etInput.text.toString().trim()
            if (text.isNotEmpty()) sendMessage(text)
        }
        binding.btnTask.setOnClickListener { checkVipFromServerAndNavigate { startActivity(Intent(requireContext(), TaskListActivity::class.java)) } }
        binding.btnModel.setOnClickListener { showModelSelector() }
        updateModelDisplay()
        binding.skill1.setOnClickListener { quickAction("创建表格") }
        binding.skill2.setOnClickListener { quickAction("市场调研") }
        binding.skill3.setOnClickListener { quickAction("日常记录") }
        binding.skill4.setOnClickListener { quickAction("创建合同") }
        binding.skill5.setOnClickListener { quickAction("创建网站") }
        binding.skill6.setOnClickListener { quickAction("旅行规划") }
    }

    private fun startBtnGlow() {
        btnGlowAnim = ValueAnimator.ofFloat(0.4f, 0.7f, 0.4f).apply {
            duration = 2500
            repeatCount = ValueAnimator.INFINITE
            addUpdateListener { binding.btnStart.translationZ = (it.animatedValue as Float) * 8f }
            start()
        }
    }

    private fun toggleSidebar() {
        val sidebar = SidebarDrawer(requireContext(), null) { conversation ->
            startActivity(Intent(requireContext(), ChatActivity::class.java).apply {
                putExtra("session_id", conversation.session_id.ifEmpty { conversation.model })
            })
        }; sidebar.show()
    }



    private fun checkVipFromServerAndNavigate(onVip: () -> Unit) {
        lifecycleScope.launch {
            try {
                val isVip = withContext(kotlinx.coroutines.Dispatchers.IO) {
                    val request = okhttp3.Request.Builder()
                        .url("https://ai.xianbaba188.cn/api/auth/check-vip")
                        .get()
                        .build()
                    val client = com.chuangpu.ai.network.ApiClient.getClient(requireContext())
                    val response = client.newCall(request).execute()
                    response.code == 200
                }
                prefs.setIsVip(isVip)
                if (isVip) onVip() else startActivity(Intent(requireContext(), VipActivity::class.java))
            } catch (e: Exception) {
                // 网络异常不放行，安全优先
                Toast.makeText(requireContext(), "网络异常，请重试", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun startChat() {
        checkVipFromServerAndNavigate {
            startActivity(Intent(requireContext(), ChatActivity::class.java).apply { putExtra("new", true) })
        }
    }

    private fun sendMessage(text: String) {
        checkVipFromServerAndNavigate {
            binding.etInput.text?.clear()
            startActivity(Intent(requireContext(), ChatActivity::class.java).apply {
                putExtra("msg", text); putExtra("send", true); putExtra("new", true)
            })
        }
    }

    private fun quickAction(skill: String) { sendMessage("帮我$skill") }

    private fun showModelSelector() {
        binding.etInput.clearFocus()
        val dialog = BottomSheetDialog(requireContext())
        val view = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_model_selector, null)
        dialog.setContentView(view)
        val modelList = view.findViewById<LinearLayout>(R.id.modelListContainer)
        modelList.removeAllViews()
        for (model in availableModels) {
            val itemView = LayoutInflater.from(requireContext()).inflate(R.layout.item_model, modelList, false)
            val tvName = itemView.findViewById<TextView>(R.id.tvModelName)
            val tvBadge = itemView.findViewById<TextView>(R.id.tvModelBadge)
            val tvCheck = itemView.findViewById<TextView>(R.id.tvModelCheck)
            tvName.text = model.name
            tvBadge.visibility = if (model.available) View.GONE else View.VISIBLE
            if (!model.available) tvBadge.text = "即将上线"
            if (model.id == currentModel) {
                itemView.setBackgroundResource(R.drawable.bg_model_active)
                tvCheck.visibility = View.VISIBLE; tvCheck.text = "✓"
            } else { tvCheck.visibility = View.GONE }
            itemView.setOnClickListener {
                if (!model.available) { Toast.makeText(requireContext(), "该模型即将上线", Toast.LENGTH_SHORT).show(); return@setOnClickListener }
                currentModel = model.id; prefs.setCurrentModel(model.id); updateModelDisplay(); dialog.dismiss()
            }
            modelList.addView(itemView)
        }
        view.findViewById<TextView>(R.id.tvCancel)?.setOnClickListener { dialog.dismiss() }
        dialog.show()
    }

    private fun updateModelDisplay() {
        val modelName = availableModels.find { it.id == currentModel }?.name ?: "DeepSeek V3"
        binding.btnModel.text = "● $modelName ▾"
    }

    override fun onDestroyView() {
        super.onDestroyView()
        btnGlowAnim?.cancel()
        binding.lobsterEmoji.destroy()
        _binding = null
    }
}
