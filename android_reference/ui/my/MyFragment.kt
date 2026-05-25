package com.chuangpu.ai.ui.my

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import com.chuangpu.ai.BuildConfig
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.FragmentMyBinding
import com.chuangpu.ai.network.ApiService
import com.chuangpu.ai.ui.chat.ChatActivity
import com.chuangpu.ai.ui.history.HistoryActivity
import com.chuangpu.ai.ui.login.LoginActivity
import com.chuangpu.ai.ui.memory.MemoryActivity
import com.chuangpu.ai.ui.settings.SettingsActivity
import com.chuangpu.ai.ui.skill.SkillFragment
import com.chuangpu.ai.ui.task.TaskListActivity
import com.chuangpu.ai.ui.vip.VipActivity
import com.chuangpu.ai.util.PreferencesManager
import com.chuangpu.ai.util.ThemeHelper
import com.chuangpu.ai.util.UpdateChecker
import android.widget.Toast
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import com.bumptech.glide.Glide
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import org.json.JSONObject
import kotlinx.coroutines.launch

class MyFragment : Fragment() {
    
    private var _binding: FragmentMyBinding? = null
    private val binding get() = _binding!!
    
    private lateinit var apiService: ApiService
    private lateinit var prefs: PreferencesManager
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentMyBinding.inflate(inflater, container, false)
        return binding.root
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        apiService = ApiService(requireContext())
        prefs = PreferencesManager.getInstance(requireContext())
        
        // 应用主题
        ThemeHelper.applyToView(binding.root, prefs)
        
        setupUI()
        loadData()
    }
    
    private fun setupUI() {
        // 用户信息
        val nickname = prefs.getUserNickname()
        val name = prefs.getUserName()
        binding.tvUserName.text = if (!nickname.isNullOrEmpty()) nickname else "用户${prefs.getUserId()}"
        binding.tvUserId.text = "ID: ${prefs.getUserId()}"
        
        // 版本号读BuildConfig
        binding.tvAboutVersion.text = "v${BuildConfig.VERSION_NAME}"
        
        // 菜单点击
        binding.vipBanner.setOnClickListener {
            startActivity(Intent(requireContext(), VipActivity::class.java))
        }
        
        binding.menuHistory.setOnClickListener {
            startActivity(Intent(requireContext(), HistoryActivity::class.java))
        }
        
        binding.menuMemory.setOnClickListener {
            startActivity(Intent(requireContext(), MemoryActivity::class.java))
        }
        
        binding.menuTasks.setOnClickListener {
            startActivity(Intent(requireContext(), TaskListActivity::class.java))
        }
        
        binding.menuSkill.setOnClickListener {
            (activity as? com.chuangpu.ai.ui.main.MainActivity)?.let { act ->
                val tabSkill = act.findViewById<android.view.View>(com.chuangpu.ai.R.id.tabSkill)
                tabSkill?.performClick()
            }
        }
        
        binding.menuSettings.setOnClickListener {
            startActivity(Intent(requireContext(), SettingsActivity::class.java))
        }
        
        binding.menuAbout.setOnClickListener {
            AlertDialog.Builder(requireContext())
                .setTitle("关于我们")
                .setMessage("创普AI v${BuildConfig.VERSION_NAME}\n\n智能对话 · 无限可能\n\n越用越懂你的专属AI助手")
                .setPositiveButton("确定", null)
                .show()
        }
        
        // 退出登录
        binding.btnLogout.setOnClickListener {
            AlertDialog.Builder(requireContext())
                .setTitle("提示")
                .setMessage("确定要退出登录吗？")
                .setPositiveButton("确定") { _, _ ->
                    prefs.logout()
                    startActivity(Intent(requireContext(), LoginActivity::class.java))
                    activity?.finish()
                }
                .setNegativeButton("取消", null)
                .show()
        }
    }
    
    private fun loadData() {
        fetchAppConfig()
        // FREE用户不请求VIP接口，直接显示0
        if (!prefs.isVip()) {
            binding.tvConversations.text = "0"
            binding.tvMessages.text = "0"
            binding.tvCredits.text = "0"
            return
        }
        lifecycleScope.launch {
            val convResult = apiService.getConversations()
            if (convResult?.code == 0) {
                val conversations = convResult.data?.list ?: emptyList()
                binding.tvConversations.text = conversations.size.toString()
                val totalMessages = conversations.sumOf { it.messageCount }
                binding.tvMessages.text = totalMessages.toString()
            }
            
            val creditResult = apiService.getCreditBalance()
            if (creditResult?.code == 0) {
                binding.tvCredits.text = (creditResult.data?.credits ?: 0).toString()
            }
        }
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
    private fun fetchAppConfig() {
        lifecycleScope.launch {
            try {
                val client = okhttp3.OkHttpClient.Builder()
                    .connectTimeout(5, java.util.concurrent.TimeUnit.SECONDS)
                    .build()
                val request = okhttp3.Request.Builder()
                    .url("http://portal.ai188.xianbaba188.cn/api/admin/app-config")
                    .get()
                    .build()
                val response = client.newCall(request).execute()
                val body = response.body?.string()
                if (body != null) {
                    val json = JSONObject(body)
                    if (json.optInt("code") == 0) {
                        val data = json.optJSONObject("data")
                        if (data != null) {
                            prefs.setAppConfig(data.toString())
                            val iconUrl = data.optString("app_icon", "")
                            if (iconUrl.isNotEmpty()) {
                                val fullUrl = "http://portal.ai188.xianbaba188.cn" + iconUrl
                                prefs.setAppIconUrl(fullUrl)
                                loadAppIcon(fullUrl)
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                // Silently fail, use default icon
            }
        }
    }

    private fun loadAppIcon(url: String) {
        try {
            Glide.with(this)
                .asBitmap()
                .load(url)
                .circleCrop()
                .into(object : CustomTarget<Bitmap>() {
                    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
                        binding.avatar.background = BitmapDrawable(resources, resource)
                    }
                    override fun onLoadCleared(placeholder: android.graphics.drawable.Drawable?) {
                        // Keep default
                    }
                })
        } catch (e: Exception) {
            // Fallback to default
        }
    }

}
