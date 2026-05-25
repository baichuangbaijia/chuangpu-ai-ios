package com.chuangpu.ai.ui.connect

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.ActivityConnectingBinding
import com.chuangpu.ai.network.ApiService
import com.chuangpu.ai.ui.chat.ChatActivity
import com.chuangpu.ai.ui.main.MainActivity
import com.chuangpu.ai.util.PreferencesManager
import kotlinx.coroutines.launch

class ConnectingActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityConnectingBinding
    private lateinit var apiService: ApiService
    private val handler = Handler(Looper.getMainLooper())
    private var pollCount = 0
    private val maxPolls = 40 // 最多轮询2分钟(每3秒一次)
    
    private val stageMessages = listOf(
        "正在分配云主机..." to "正在连接",
        "正在安装工作环境..." to "正在连接", 
        "正在启动龙虾..." to "正在连接"
    )
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityConnectingBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        apiService = ApiService(this)
        
        // 关闭按钮
        binding.btnClose.setOnClickListener {
            stopPolling()
            // 跳回主页
            val intent = Intent(this, MainActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP
            startActivity(intent)
            finish()
        }
        
        // 开始轮询容器状态
        startPolling()
    }
    
    private fun startPolling() {
        pollContainerStatus()
    }
    
    private fun pollContainerStatus() {
        if (pollCount >= maxPolls) {
            // 超时
            updateStageText("连接超时，请稍后重试", "连接失败")
            binding.tvDotAnimation.text = "!"
            return
        }
        
        lifecycleScope.launch {
            try {
                val result = apiService.getContainerStatus()
                if (result != null && result.code == 0) {
                    val containerStatus = result.data?.get("container_status") as? String ?: "none"
                    when (containerStatus) {
                        "running" -> {
                            // 容器就绪，跳转聊天页
                            stopPolling()
                            updateStageText("连接成功！", "已就绪")
                            binding.tvDotAnimation.text = "✓"
                            binding.dotIndicator.setBackgroundResource(R.drawable.bg_online_dot)
                            // 延迟0.8秒跳转
                            handler.postDelayed({
                                val intent = Intent(this@ConnectingActivity, MainActivity::class.java)
                                intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP
                                startActivity(intent)
                                finish()
                            }, 800)
                            return@launch
                        }
                        "creating" -> {
                            // 还在创建，更新阶段文字
                            val stageIndex = (pollCount / 4) % stageMessages.size
                            val (subMsg, mainMsg) = stageMessages[stageIndex]
                            updateStageText(subMsg, mainMsg)
                        }
                        "error" -> {
                            stopPolling()
                            updateStageText("容器创建失败，请联系客服", "连接失败")
                            binding.tvDotAnimation.text = "!"
                            return@launch
                        }
                        else -> {
                            val stageIndex = (pollCount / 4) % stageMessages.size
                            val (subMsg, mainMsg) = stageMessages[stageIndex]
                            updateStageText(subMsg, mainMsg)
                        }
                    }
                }
            } catch (e: Exception) {
                // 网络错误，继续轮询
            }
            
            pollCount++
            // 3秒后再轮询
            handler.postDelayed({ pollContainerStatus() }, 3000)
        }
    }
    
    private fun updateStageText(subText: String, mainText: String) {
        binding.tvSubStatus.text = subText
        binding.tvMainStatus.text = mainText
    }
    
    private fun stopPolling() {
        handler.removeCallbacksAndMessages(null)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopPolling()
    }
}