package com.chuangpu.ai.ui.settings

import android.app.AlertDialog
import android.os.Bundle
import android.text.InputType
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.chuangpu.ai.databinding.ActivitySettingsBinding
import com.chuangpu.ai.BuildConfig
import com.chuangpu.ai.network.ApiService
import com.chuangpu.ai.ui.login.LoginActivity
import com.chuangpu.ai.util.PreferencesManager
import com.chuangpu.ai.util.ThemeHelper
import kotlinx.coroutines.launch
import java.io.File

class SettingsActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivitySettingsBinding
    private lateinit var apiService: ApiService
    private lateinit var prefs: PreferencesManager
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySettingsBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        ThemeHelper.applyToActivity(this)
        binding.tvVersion.text = "v${BuildConfig.VERSION_NAME}"
        
        apiService = ApiService(this)
        prefs = PreferencesManager.getInstance(this)
        
        setupUI()
        loadUserInfo()
        calculateCacheSize()
    }
    
    private fun setupUI() {
        binding.btnBack.setOnClickListener { finish() }
        
        // 修改昵称
        binding.itemNickname.setOnClickListener { showEditNicknameDialog() }
        
        // 修改密码 - 真正对接后端
        binding.itemPassword.setOnClickListener { showChangePasswordDialog() }
        
        // 消息通知
        binding.switchNotification.isChecked = prefs.isNotificationEnabled()
        binding.switchNotification.setOnCheckedChangeListener { _, isChecked ->
            prefs.setNotification(isChecked)
        }
        
        // 清除缓存 - 真正清
        binding.itemClearCache.setOnClickListener { showClearCacheDialog() }
        
        // 检查更新
        binding.itemUpdate.setOnClickListener {
            lifecycleScope.launch { com.chuangpu.ai.util.UpdateChecker.check(this@SettingsActivity, silent = false) }
        }
        
        // 隐私政策 - APP内弹窗
        binding.itemPrivacy.setOnClickListener { showAgreementDialog("隐私政策", privacyHtml) }
        
        // 用户协议 - APP内弹窗
        binding.itemAgreement.setOnClickListener { showAgreementDialog("用户协议", agreementHtml) }
        
        // 退出登录
        binding.btnLogout.setOnClickListener { showLogoutDialog() }
        
        // 主题选择
        updateThemeUI()
        binding.themeDefault.setOnClickListener { selectTheme("default") }
        binding.themeDeepSpace.setOnClickListener { selectTheme("deep-space") }
        binding.themeDarkBlue.setOnClickListener { selectTheme("dark-blue") }
        binding.themeStarPurple.setOnClickListener { selectTheme("star-purple") }
    }
    
    private fun loadUserInfo() {
        binding.tvNickname.text = prefs.getUserNickname() ?: "未设置"
        lifecycleScope.launch {
            val result = apiService.getMe()
            if (result?.code == 0) {
                result.data?.let { user ->
                    binding.tvNickname.text = user.nickname ?: user.name
                }
            }
        }
    }
    
    // ===== 修改密码 =====
    private fun showChangePasswordDialog() {
        val oldPwd = EditText(this).apply {
            hint = "请输入旧密码"
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        }
        val newPwd = EditText(this).apply {
            hint = "请输入新密码（至少6位）"
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        }
        val confirmPwd = EditText(this).apply {
            hint = "请确认新密码"
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        }
        
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(50, 30, 50, 10)
            addView(oldPwd)
            addView(newPwd)
            addView(confirmPwd)
        }
        
        AlertDialog.Builder(this)
            .setTitle("修改密码")
            .setView(layout)
            .setPositiveButton("确定") { _, _ ->
                val old = oldPwd.text.toString().trim()
                val new = newPwd.text.toString().trim()
                val confirm = confirmPwd.text.toString().trim()
                when {
                    old.isEmpty() -> Toast.makeText(this, "请输入旧密码", Toast.LENGTH_SHORT).show()
                    new.length < 6 -> Toast.makeText(this, "新密码至少6位", Toast.LENGTH_SHORT).show()
                    new != confirm -> Toast.makeText(this, "两次密码不一致", Toast.LENGTH_SHORT).show()
                    else -> changePassword(old, new)
                }
            }
            .setNegativeButton("取消", null)
            .show()
    }
    
    private fun changePassword(old: String, new: String) {
        lifecycleScope.launch {
            try {
                val result = apiService.changePassword(old, new)
                if (result?.code == 0) {
                    Toast.makeText(this@SettingsActivity, "密码修改成功，请重新登录", Toast.LENGTH_LONG).show()
                    prefs.logout()
                    startActivity(android.content.Intent(this@SettingsActivity, LoginActivity::class.java))
                    finish()
                } else {
                    Toast.makeText(this@SettingsActivity, result?.message ?: "修改失败", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@SettingsActivity, "网络错误", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    // ===== 修改昵称 =====
    private fun showEditNicknameDialog() {
        val editText = EditText(this).apply {
            hint = "请输入新昵称"
            setText(prefs.getUserNickname() ?: "")
        }
        AlertDialog.Builder(this)
            .setTitle("修改昵称")
            .setView(editText)
            .setPositiveButton("确定") { _, _ ->
                val nickname = editText.text.toString().trim()
                if (nickname.isNotEmpty()) updateNickname(nickname)
            }
            .setNegativeButton("取消", null)
            .show()
    }
    
    private fun updateNickname(nickname: String) {
        lifecycleScope.launch {
            val result = apiService.updateProfile(nickname)
            if (result?.code == 0) {
                Toast.makeText(this@SettingsActivity, "昵称修改成功", Toast.LENGTH_SHORT).show()
                binding.tvNickname.text = nickname
            } else {
                Toast.makeText(this@SettingsActivity, result?.message ?: "修改失败", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    // ===== 清除缓存 - 真正计算和删除 =====
    private fun calculateCacheSize() {
        val cacheDir = cacheDir
        val size = getDirSize(cacheDir)
        binding.tvCacheSize.text = formatSize(size)
    }
    
    private fun getDirSize(dir: File): Long {
        var size = 0L
        if (dir.exists()) {
            dir.listFiles()?.forEach {
                size += if (it.isDirectory) getDirSize(it) else it.length()
            }
        }
        return size
    }
    
    private fun formatSize(size: Long): String {
        return when {
            size < 1024 -> "${size}B"
            size < 1024 * 1024 -> "${size / 1024}KB"
            else -> "${size / (1024 * 1024)}MB"
        }
    }
    
    private fun showClearCacheDialog() {
        AlertDialog.Builder(this)
            .setTitle("清除缓存")
            .setMessage("确定要清除所有缓存数据吗？")
            .setPositiveButton("确定") { _, _ ->
                deleteDir(cacheDir)
                Toast.makeText(this, "缓存已清除", Toast.LENGTH_SHORT).show()
                binding.tvCacheSize.text = "0B"
            }
            .setNegativeButton("取消", null)
            .show()
    }
    
    private fun deleteDir(dir: File) {
        if (dir.exists()) {
            dir.listFiles()?.forEach {
                if (it.isDirectory) deleteDir(it) else it.delete()
            }
        }
    }
    
    // ===== 主题 =====
    private fun selectTheme(themeId: String) {
        prefs.setTheme(themeId)
        updateThemeUI()
        Toast.makeText(this, "主题已切换", Toast.LENGTH_SHORT).show()
        recreate()
    }
    
    private fun updateThemeUI() {
        val currentTheme = prefs.getTheme()
        binding.themeDefault.alpha = if (currentTheme == "default") 1f else 0.6f
        binding.themeDeepSpace.alpha = if (currentTheme == "deep-space") 1f else 0.6f
        binding.themeDarkBlue.alpha = if (currentTheme == "dark-blue") 1f else 0.6f
        binding.themeStarPurple.alpha = if (currentTheme == "star-purple") 1f else 0.6f
    }
    
    // ===== 协议弹窗 =====
    private fun showAgreementDialog(title: String, content: String) {
        val tv = TextView(this).apply {
            text = android.text.Html.fromHtml(content, android.text.Html.FROM_HTML_MODE_COMPACT)
            textSize = 14f
            setTextColor(0xFFCCCCCC.toInt())
            setPadding(40, 24, 40, 24)
        }
        val scrollView = android.widget.ScrollView(this).apply { addView(tv) }
        AlertDialog.Builder(this)
            .setTitle(title)
            .setView(scrollView)
            .setPositiveButton("确定", null)
            .show()
    }
    
    private val agreementHtml = """
    <h2>一、服务说明</h2>
    <p>创普AI是一款由创普科技运营的人工智能对话助手产品。本服务通过AI技术为用户提供智能聊天、技能服务、定时任务管理等功能。</p>
    <h2>二、账号注册与使用</h2>
    <p>您可以通过手机号注册的方式创建创普AI账号。在注册时，您需要提供真实、准确、有效的个人信息，并设置安全的登录密码。</p>
    <h2>三、用户行为规范</h2>
    <ul>
    <li>遵守中华人民共和国法律法规，不得利用本服务从事违法活动；</li>
    <li>不得发布或传播违反公序良俗、损害社会公共利益的内容；</li>
    <li>不得攻击、侵入、干扰本服务的正常运行或破坏系统安全；</li>
    <li>不得利用AI服务生成、传播违法信息、虚假信息或有害内容。</li>
    </ul>
    <h2>四、AI生成内容说明</h2>
    <p>创普AI生成的内容仅供参考之用，不构成任何形式的专业建议。</p>
    <h2>五、知识产权</h2>
    <p>您通过本服务输入的内容，其知识产权归您所有。创普AI的产品名称、界面设计、程序代码的知识产权归创普科技所有。</p>
    <h2>六、免责声明</h2>
    <ul>
    <li>AI可能因技术限制产生不准确、不适当的内容，您需自行判断并承担使用风险；</li>
    <li>因不可抗力导致的服务中断或数据丢失，我们不承担责任；</li>
    </ul>
    <p>联系邮箱：support@chuangpu-ai.com</p>
    """.trimIndent()
    
    private val privacyHtml = """
    <h2>一、我们收集的信息</h2>
    <ul>
    <li>账号信息：手机号码、昵称、头像；</li>
    <li>聊天记录：您与创普AI的对话内容；</li>
    <li>AI记忆数据：AI从对话中提取并存储的关键信息；</li>
    <li>设备信息：设备型号、操作系统版本等基本信息。</li>
    </ul>
    <h2>二、信息的用途</h2>
    <p>我们收集您的信息主要用于：提供AI对话服务、个性化服务、安全防护、产品改进、法律法规要求。</p>
    <h2>三、信息存储</h2>
    <p>您的个人信息存储在位于中国境内的服务器上。我们采用数据加密、访问控制、安全审计等措施保护您的信息安全。</p>
    <h2>四、AI记忆说明</h2>
    <p>创普AI具备记忆功能，可以从您的对话中提取关键信息并存储。您可以随时在"我的记忆"页面查看、编辑或删除记忆内容。</p>
    <h2>五、您的权利</h2>
    <p>您享有知情权、访问权、更正权、删除权、撤回同意、账号注销等权利。</p>
    <p>联系邮箱：support@chuangpu-ai.com</p>
    """.trimIndent()
    
    // ===== 退出登录 =====
    private fun showLogoutDialog() {
        AlertDialog.Builder(this)
            .setTitle("退出登录")
            .setMessage("确定要退出登录吗？")
            .setPositiveButton("确定") { _, _ ->
                prefs.logout()
                startActivity(android.content.Intent(this, LoginActivity::class.java))
                finish()
            }
            .setNegativeButton("取消", null)
            .show()
    }
}