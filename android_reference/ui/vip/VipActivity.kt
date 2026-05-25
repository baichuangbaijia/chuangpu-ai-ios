package com.chuangpu.ai.ui.vip

import android.content.Intent
import android.os.Bundle
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.ActivityVipBinding
import com.chuangpu.ai.network.ApiService
import com.chuangpu.ai.ui.chat.ChatActivity
import com.chuangpu.ai.util.PreferencesManager
import kotlinx.coroutines.launch

class VipActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityVipBinding
    private lateinit var apiService: ApiService
    
    private var selectedPlan = 0
    private val planIds = arrayOf(1, 2, 3)
    private val planPrices = arrayOf("298/年", "198/月", "68/周")
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityVipBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        apiService = ApiService(this)
        setupUI()
    }
    
    private fun setupUI() {
        binding.btnBack.setOnClickListener { finish() }
        binding.tvRules.setOnClickListener { showRules() }
        
        binding.planYearly.setOnClickListener { selectPlan(0) }
        binding.planMonthly.setOnClickListener { selectPlan(1) }
        binding.planWeekly.setOnClickListener { selectPlan(2) }
        
        binding.cbAgree.setOnCheckedChangeListener { _, isChecked ->
            binding.btnSubmit.isEnabled = isChecked
            binding.btnSubmit.alpha = if (isChecked) 1f else 0.5f
        }
        
        // 开通会员 - 调测试接口直接激活
        binding.btnSubmit.setOnClickListener {
            if (!binding.cbAgree.isChecked) {
                Toast.makeText(this, "请先同意会员服务协议", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            activateTestVip()
        }
        binding.btnSubmit.isEnabled = false
        binding.btnSubmit.alpha = 0.5f
        
        binding.tvAgreement.setOnClickListener { showAgreementDialog("会员服务协议", agreementHtml) }
        binding.tvRestore.setOnClickListener { Toast.makeText(this, "暂无订阅记录", Toast.LENGTH_SHORT).show() }
        binding.tvPrivacy.setOnClickListener { showAgreementDialog("隐私政策", privacyHtml) }
        binding.tvMemberAgreement.setOnClickListener { showAgreementDialog("会员服务协议", agreementHtml) }
        
        selectPlan(0)
    }
    
    private fun activateTestVip() {
        binding.btnSubmit.isEnabled = false
        binding.btnSubmit.text = "开通中..."
        
        lifecycleScope.launch {
            try {
                val result = apiService.activateTestVip()
                if (result != null && result.code == 0) {
                    PreferencesManager.getInstance(this@VipActivity).setIsVip(true)
                    showSuccessDialog()
                } else {
                    val msg = result?.message ?: "开通失败"
                    Toast.makeText(this@VipActivity, msg, Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@VipActivity, "网络错误: ${e.message}", Toast.LENGTH_SHORT).show()
            } finally {
                binding.btnSubmit.isEnabled = binding.cbAgree.isChecked
                binding.btnSubmit.text = "开通会员"
            }
        }
    }
    
    private fun showSuccessDialog() {
        val dialogView = layoutInflater.inflate(R.layout.dialog_vip_success, null)
        
        val dialog = AlertDialog.Builder(this, R.style.TransparentDialog)
            .setView(dialogView)
            .setCancelable(false)
            .create()
        
        dialogView.findViewById<TextView>(R.id.btnStartNow).setOnClickListener {
            dialog.dismiss()
            // 直接跳聊天页
            val intent = Intent(this, ChatActivity::class.java)
            intent.putExtra("show_connecting", true)
            startActivity(intent)
            finish()
        }
        
        dialog.show()
    }
    
    private fun showAgreementDialog(title: String, content: String) {
        val tv = android.widget.TextView(this).apply {
            text = android.text.Html.fromHtml(content, android.text.Html.FROM_HTML_MODE_COMPACT)
            textSize = 14f
            setTextColor(0xFFCCCCCC.toInt())
            setPadding(40, 24, 40, 24)
        }
        val scrollView = android.widget.ScrollView(this).apply {
            addView(tv)
        }
        AlertDialog.Builder(this)
            .setTitle(title)
            .setView(scrollView)
            .setPositiveButton("确定", null)
            .show()
    }

    private val agreementHtml = """
    <h2>一、服务说明</h2>
    <p>创普AI是一款由创普科技运营的人工智能对话助手产品。</p>
    <h2>二、账号注册与使用</h2>
    <p>您可以通过手机号注册的方式创建创普AI账号。</p>
    <h2>三、用户行为规范</h2>
    <ul>
    <li>遵守中华人民共和国法律法规；</li>
    <li>不得利用AI服务生成违法信息；</li>
    </ul>
    <p>联系邮箱：support@chuangpu-ai.com</p>
    """.trimIndent()

    private val privacyHtml = """
    <h2>一、我们收集的信息</h2>
    <ul>
    <li>账号信息：手机号码、昵称、头像；</li>
    <li>聊天记录：您与创普AI的对话内容；</li>
    </ul>
    <p>联系邮箱：support@chuangpu-ai.com</p>
    """.trimIndent()
    
    private fun selectPlan(index: Int) {
        selectedPlan = index
        binding.tvRenewalHint.text = "到期按\u00a5${planPrices[index]}自动订阅，可随时取消"
        updatePlanUI()
    }
    
    private fun updatePlanUI() {
        val selBg = R.drawable.plan_selected
        val unselBg = R.drawable.plan_unselected
        
        binding.planYearly.setBackgroundResource(if (selectedPlan == 0) selBg else unselBg)
        binding.planMonthly.setBackgroundResource(if (selectedPlan == 1) selBg else unselBg)
        binding.planWeekly.setBackgroundResource(if (selectedPlan == 2) selBg else unselBg)
    }
    
    private fun showRules() {
        AlertDialog.Builder(this)
            .setTitle("积分规则")
            .setMessage("""
                1. 会员赠送积分：包年50000、包月10000、包周3000
                2. AI对话消耗积分，按模型和长度扣减
                3. 积分不可转让、不可提现
                4. 到期未续费，剩余积分清零
            """.trimIndent())
            .setPositiveButton("确定", null)
            .show()
    }
}