package com.chuangpu.ai.ui.splash

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity
import com.chuangpu.ai.databinding.ActivitySplashBinding
import com.chuangpu.ai.ui.login.LoginActivity
import com.chuangpu.ai.ui.main.MainActivity
import com.chuangpu.ai.util.PreferencesManager

@SuppressLint("CustomSplashScreen")
class SplashActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivitySplashBinding
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )
        
        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        Handler(Looper.getMainLooper()).postDelayed({
            navigateToNext()
        }, 1500)
    }
    
    private fun navigateToNext() {
        val prefs = PreferencesManager.getInstance(this)
        val intent = if (prefs.isLoggedIn()) {
            Intent(this, MainActivity::class.java)
        } else {
            Intent(this, LoginActivity::class.java)
        }
        startActivity(intent)
        finish()
    }
}
