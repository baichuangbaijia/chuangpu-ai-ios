package com.chuangpu.ai.ui.login

import android.view.animation.AnimationUtils
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.view.View
import android.view.animation.AlphaAnimation
import android.view.animation.Animation
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.chuangpu.ai.databinding.ActivityLoginBinding
import com.chuangpu.ai.network.ApiService
import com.chuangpu.ai.ui.main.MainActivity
import com.chuangpu.ai.util.PreferencesManager
import kotlinx.coroutines.launch

class LoginActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityLoginBinding
    private lateinit var apiService: ApiService
    private lateinit var prefs: PreferencesManager
    
    private var mode = "sms" // sms | pwd | register
    private var countdownTimer: CountDownTimer? = null
    private var isSending = false
    private var isLoading = false
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        apiService = ApiService(this)
        prefs = PreferencesManager.getInstance(this)
        
        setupUI()
        startBgAnimation()
    }
    
    private fun setupUI() {
        // Tab切换
        binding.tabSms.setOnClickListener { switchMode("sms") }
        binding.tabPwd.setOnClickListener { switchMode("pwd") }
        
        // 发送验证码
        binding.btnCode.setOnClickListener { sendCode() }
        
        // 登录
        binding.btnLogin.setOnClickListener { handleLogin() }
        
        // 切换注册
        binding.tvSwitch.setOnClickListener { 
            mode = "register"
            updateUI()
        }
        
        // 设置协议文本
        binding.tvAgreement.text = "登录即表示同意《用户协议》和《隐私政策》"
        
        // 手机号输入监听
        binding.etPhone.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                binding.tvError.visibility = View.GONE
            }
        })
        
        updateUI()
    }
    
    private fun switchMode(newMode: String) {
        mode = newMode
        updateUI()
    }
    
    private fun updateUI() {
        when (mode) {
            "sms" -> {
                binding.tabSms.setBackgroundResource(com.chuangpu.ai.R.drawable.bg_tab_selected)
                binding.tabSms.setTextColor(getColor(com.chuangpu.ai.R.color.text_white))
                binding.tabPwd.setBackgroundResource(android.graphics.Color.TRANSPARENT)
                binding.tabPwd.setTextColor(getColor(com.chuangpu.ai.R.color.text_gray))
                binding.codeGroup.visibility = View.VISIBLE
                binding.etPassword.visibility = View.GONE
                binding.btnLogin.text = "登录"
                binding.tvSwitch.text = "还没有账号？立即注册"
                binding.tvAgreement.visibility = View.VISIBLE
            }
            "pwd" -> {
                binding.tabPwd.setBackgroundResource(com.chuangpu.ai.R.drawable.bg_tab_selected)
                binding.tabPwd.setTextColor(getColor(com.chuangpu.ai.R.color.text_white))
                binding.tabSms.setBackgroundResource(android.graphics.Color.TRANSPARENT)
                binding.tabSms.setTextColor(getColor(com.chuangpu.ai.R.color.text_gray))
                binding.codeGroup.visibility = View.GONE
                binding.etPassword.visibility = View.VISIBLE
                binding.btnLogin.text = "登录"
                binding.tvSwitch.text = "还没有账号？立即注册"
                binding.tvAgreement.visibility = View.VISIBLE
            }
            "register" -> {
                binding.tabSms.setBackgroundResource(android.graphics.Color.TRANSPARENT)
                binding.tabPwd.setBackgroundResource(android.graphics.Color.TRANSPARENT)
                binding.tabSms.setTextColor(getColor(com.chuangpu.ai.R.color.text_gray))
                binding.tabPwd.setTextColor(getColor(com.chuangpu.ai.R.color.text_gray))
                binding.codeGroup.visibility = View.VISIBLE
                binding.etPassword.visibility = View.VISIBLE
                binding.etPassword.hint = "设置密码（至少6位）"
                binding.btnLogin.text = "注册"
                binding.tvSwitch.text = "已有账号？立即登录"
                binding.tvAgreement.visibility = View.VISIBLE
            }
        }
        binding.tvError.visibility = View.GONE
    }
    
    private fun startBgAnimation() {
        val anim = android.view.animation.AnimationUtils.loadAnimation(this, android.R.anim.fade_in)
        
        binding.loginBg.startAnimation(anim)
        
        // Logo脉冲动画
        val pulseAnim = AlphaAnimation(0.9f, 1.1f).apply {
            duration = 2000
            repeatMode = Animation.REVERSE
            repeatCount = Animation.INFINITE
        }
        binding.logoOrb.startAnimation(pulseAnim)
    }
    
    private fun sendCode() {
        val phone = binding.etPhone.text.toString().trim()
        if (phone.length != 11) {
            showError("请输入正确的手机号")
            return
        }
        if (isSending) return
        
        isSending = true
        binding.btnCode.text = "发送中..."
        
        lifecycleScope.launch {
            val type = if (mode == "register") "register" else "login"
            val result = apiService.sendSmsCode(phone, type)
            
            if (result?.code == 0) {
                startCountdown()
            } else {
                val msg = result?.message ?: "发送验证码失败"
                showError(if (msg.contains("频繁")) "发送太频繁，请稍后再试" else msg)
                isSending = false
                binding.btnCode.text = "获取验证码"
            }
        }
    }
    
    private fun startCountdown() {
        countdownTimer?.cancel()
        countdownTimer = object : CountDownTimer(60000, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                binding.btnCode.text = "${millisUntilFinished / 1000}s"
                binding.btnCode.isEnabled = false
            }
            
            override fun onFinish() {
                binding.btnCode.text = "获取验证码"
                binding.btnCode.isEnabled = true
                isSending = false
            }
        }.start()
    }
    
    private fun handleLogin() {
        val phone = binding.etPhone.text.toString().trim()
        if (phone.length != 11) {
            showError("请输入正确的手机号")
            return
        }
        
        when (mode) {
            "sms" -> smsLogin(phone)
            "pwd" -> pwdLogin(phone)
            "register" -> register(phone)
        }
    }
    
    private fun smsLogin(phone: String) {
        val code = binding.etCode.text.toString().trim()
        if (code.length < 4) {
            showError("请输入验证码")
            return
        }
        
        setLoading(true)
        lifecycleScope.launch {
            val result = apiService.login(phone, code = code, loginType = "sms")
            setLoading(false)
            
            if (result?.code == 0 && result.data?.token != null) {
                prefs.saveToken(result.data.token)
                result.data.user?.let { user ->
                    prefs.saveUserInfo(user.id, user.name, user.nickname)
                    prefs.setIsVip(user.vip_level != "free" && user.vip_level != null)
                } ?: run {
                    // API returns user_id directly
                    val uid = result.data.user_id
                    prefs.saveUserInfo(uid, "", null)
                }
                navigateToMain()
            } else {
                val msg = result?.message ?: "登录失败"
                showError(if (msg.contains("验证码")) "验证码错误或已过期" else msg)
            }
        }
    }
    
    private fun pwdLogin(phone: String) {
        val password = binding.etPassword.text.toString().trim()
        if (password.length < 6) {
            showError("密码至少6位")
            return
        }
        
        setLoading(true)
        lifecycleScope.launch {
            val result = apiService.login(phone, password = password, loginType = "pwd")
            setLoading(false)
            
            if (result?.code == 0 && result.data?.token != null) {
                prefs.saveToken(result.data.token)
                result.data.user?.let { user ->
                    prefs.saveUserInfo(user.id, user.name, user.nickname)
                    prefs.setIsVip(user.vip_level != "free" && user.vip_level != null)
                } ?: run {
                    val uid = result.data.user_id
                    prefs.saveUserInfo(uid, "", null)
                }
                navigateToMain()
            } else {
                val msg = result?.message ?: "登录失败"
                showError(if (msg.contains("密码")) "手机号或密码错误" else msg)
            }
        }
    }
    
    private fun register(phone: String) {
        val code = binding.etCode.text.toString().trim()
        val password = binding.etPassword.text.toString().trim()
        
        if (code.length < 4) {
            showError("请输入验证码")
            return
        }
        if (password.length < 6) {
            showError("密码至少6位")
            return
        }
        
        setLoading(true)
        lifecycleScope.launch {
            val result = apiService.register(phone, password, code)
            setLoading(false)
            
            if (result?.code == 0 && result.data?.token != null) {
                prefs.saveToken(result.data.token)
                result.data.user?.let { user ->
                    prefs.saveUserInfo(user.id, user.name, user.nickname)
                    prefs.setIsVip(user.vip_level != "free" && user.vip_level != null)
                } ?: run {
                    val uid = result.data.user_id
                    prefs.saveUserInfo(uid, "", null)
                }
                navigateToMain()
            } else {
                val msg = result?.message ?: "注册失败"
                showError(
                    when {
                        msg.contains("已注册") -> "手机号已注册，请登录"
                        msg.contains("验证码") -> "验证码错误或已过期"
                        else -> msg
                    }
                )
            }
        }
    }
    
    private fun setLoading(loading: Boolean) {
        isLoading = loading
        binding.btnLogin.isEnabled = !loading
        binding.btnLogin.text = when {
            mode == "register" && loading -> "注册中..."
            mode != "register" && loading -> "登录中..."
            else -> if (mode == "register") "注册" else "登录"
        }
    }
    
    private fun showError(msg: String) {
        binding.tvError.text = msg
        binding.tvError.visibility = View.VISIBLE
    }
    
    private fun navigateToMain() {
        startActivity(Intent(this, MainActivity::class.java))
        finish()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        countdownTimer?.cancel()
    }
}
