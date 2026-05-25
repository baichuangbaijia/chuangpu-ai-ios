package com.chuangpu.ai.ui.main

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.ActivityMainBinding
import com.chuangpu.ai.ui.home.HomeFragment
import com.chuangpu.ai.ui.vip.VipActivity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import com.chuangpu.ai.ui.my.MyFragment
import com.chuangpu.ai.ui.skill.SkillFragment
import com.chuangpu.ai.util.UpdateChecker
import com.chuangpu.ai.util.ThemeHelper
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private var currentTab = 0
    private val vipReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.chuangpu.ai.ACTION_VIP_REQUIRED") {
                startActivity(Intent(this@MainActivity, VipActivity::class.java))
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        ThemeHelper.applyToActivity(this)
        setupTabs()

        // 注册VIP广播接收器
        registerReceiver(vipReceiver, IntentFilter("com.chuangpu.ai.ACTION_VIP_REQUIRED"))
        
        // 检查更新
        lifecycleScope.launch { UpdateChecker.check(this@MainActivity) }
        
        // 默认显示首页
        if (savedInstanceState == null) {
            showFragment(HomeFragment())
        }
    }
    
    private fun setupTabs() {
        binding.tabHome.setOnClickListener { selectTab(0) }
        binding.tabSkill.setOnClickListener { selectTab(1) }
        binding.tabMy.setOnClickListener { selectTab(2) }
    }
    
    private fun selectTab(index: Int) {
        if (currentTab == index) return
        currentTab = index
        
        updateTabUI()
        
        val fragment = when (index) {
            0 -> HomeFragment()
            1 -> SkillFragment()
            2 -> MyFragment()
            else -> HomeFragment()
        }
        
        showFragment(fragment)
    }
    
    private fun updateTabUI() {
        val activeColor = getColor(R.color.primary_purple)
        val inactiveColor = getColor(R.color.text_gray_dark)
        
        // 首页
        binding.tvHome.setTextColor(if (currentTab == 0) activeColor else inactiveColor)
        binding.ivHome.setColorFilter(if (currentTab == 0) activeColor else inactiveColor)
        
        // 技能
        binding.tvSkill.setTextColor(if (currentTab == 1) activeColor else inactiveColor)
        binding.ivSkill.setColorFilter(if (currentTab == 1) activeColor else inactiveColor)
        
        // 我的
        binding.tvMy.setTextColor(if (currentTab == 2) activeColor else inactiveColor)
        binding.ivMy.setColorFilter(if (currentTab == 2) activeColor else inactiveColor)
    }
    
    private fun showFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .commit()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        try { unregisterReceiver(vipReceiver) } catch (_: Exception) {}
    }
    
    override fun onResume() {
        super.onResume()
        // 每次回到前台都检查更新
        lifecycleScope.launch { UpdateChecker.check(this@MainActivity) }
    }
    
    override fun onBackPressed() {
        if (currentTab != 0) {
            selectTab(0)
        } else {
            super.onBackPressed()
        }
    }
}
