package com.chuangpu.ai.ui.task

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.ActivityTaskEditBinding

import com.chuangpu.ai.network.ApiService
import kotlinx.coroutines.launch

class TaskEditActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityTaskEditBinding
    private lateinit var apiService: ApiService
    
    private var isEdit = false
    private var taskId: String? = null
    private var selectedFreq = "daily"
    
    private val freqOptions = mapOf(
        "daily" to "每天",
        "weekly" to "每周一",
        "friday" to "每周五",
        "monthly" to "每月1日",
        "custom" to "自定义"
    )
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityTaskEditBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        apiService = ApiService(this)
        
        taskId = intent.getStringExtra("taskId")
        isEdit = !taskId.isNullOrEmpty()
        
        setupUI()
        
        if (isEdit) {
            binding.tvTitle.text = "编辑任务"
            binding.btnSubmit.text = "保存修改"
            loadTask()
        } else {
            binding.tvTitle.text = "创建任务"
            binding.btnSubmit.text = "创建任务"
        }
    }
    
    private fun setupUI() {
        binding.btnBack.setOnClickListener { finish() }
        
        // 频率选项
        binding.freqDaily.setOnClickListener { selectFreq("daily") }
        binding.freqWeekly.setOnClickListener { selectFreq("weekly") }
        binding.freqFriday.setOnClickListener { selectFreq("friday") }
        binding.freqMonthly.setOnClickListener { selectFreq("monthly") }
        binding.freqCustom.setOnClickListener { selectFreq("custom") }
        
        // 提交
        binding.btnSubmit.setOnClickListener { submit() }
        
        updateFreqUI()
    }
    
    private fun selectFreq(freq: String) {
        selectedFreq = freq
        updateFreqUI()
        
        // 更新时间
        val (hour, minute) = when (freq) {
            "daily" -> Pair("08", "00")
            "weekly" -> Pair("09", "00")
            "friday" -> Pair("09", "00")
            "monthly" -> Pair("08", "00")
            else -> Pair(binding.etHour.text.toString().padStart(2, '0'), 
                          binding.etMinute.text.toString().padStart(2, '0'))
        }
        binding.etHour.setText(hour)
        binding.etMinute.setText(minute)
    }
    
    private fun updateFreqUI() {
        val activeBg = R.drawable.bg_freq_selected
        val inactiveBg = R.drawable.bg_freq_normal
        
        binding.freqDaily.setBackgroundResource(if (selectedFreq == "daily") activeBg else inactiveBg)
        binding.freqWeekly.setBackgroundResource(if (selectedFreq == "weekly") activeBg else inactiveBg)
        binding.freqFriday.setBackgroundResource(if (selectedFreq == "friday") activeBg else inactiveBg)
        binding.freqMonthly.setBackgroundResource(if (selectedFreq == "monthly") activeBg else inactiveBg)
        binding.freqCustom.setBackgroundResource(if (selectedFreq == "custom") activeBg else inactiveBg)
        
        binding.freqDaily.setTextColor(getColor(if (selectedFreq == "daily") R.color.text_white else R.color.text_gray))
        binding.freqWeekly.setTextColor(getColor(if (selectedFreq == "weekly") R.color.text_white else R.color.text_gray))
        binding.freqFriday.setTextColor(getColor(if (selectedFreq == "friday") R.color.text_white else R.color.text_gray))
        binding.freqMonthly.setTextColor(getColor(if (selectedFreq == "monthly") R.color.text_white else R.color.text_gray))
        binding.freqCustom.setTextColor(getColor(if (selectedFreq == "custom") R.color.text_white else R.color.text_gray))
    }
    
    private fun loadTask() {
        lifecycleScope.launch {
            val result = apiService.getTaskList()
            if (result?.code == 0) {
                val list = result.data?.list ?: emptyList()
                val task = list.find { it.id.toString() == taskId }
                if (task != null) {
                    binding.etName.setText(task.name)
                    binding.etPrompt.setText(task.prompt)
                    binding.etDesc.setText(task.description ?: "")
                    binding.switchNotify.isChecked = task.notification_enabled
                    
                    // Parse cron
                    val parts = task.cron_expression.split(" ")
                    if (parts.size >= 2) {
                        binding.etMinute.setText(parts[0].padStart(2, '0'))
                        binding.etHour.setText(parts[1].padStart(2, '0'))
                    }
                    
                    // Match frequency
                    val cronMap = mapOf(
                        "daily" to listOf("0", parts.getOrNull(1) ?: "8", "*", "*", "*"),
                        "weekly" to listOf("0", parts.getOrNull(1) ?: "9", "*", "*", "1"),
                        "friday" to listOf("0", parts.getOrNull(1) ?: "9", "*", "*", "5"),
                        "monthly" to listOf("0", parts.getOrNull(1) ?: "8", "1", "*", "*")
                    )
                    val matchedFreq = cronMap.entries.find { (_, pattern) ->
                        task.cron_expression.split(" ").let { p ->
                            p.size >= 5 && p[0] == pattern[0] && p[2] == pattern[2] && p[3] == pattern[3] && p[4] == pattern[4]
                        }
                    }?.key ?: "custom"
                    
                    selectedFreq = matchedFreq
                    if (matchedFreq == "custom") {
                        binding.etCron.setText(task.cron_expression)
                    }
                    updateFreqUI()
                }
            } else {
                Toast.makeText(this@TaskEditActivity, "加载任务失败", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun submit() {
        val name = binding.etName.text.toString().trim()
        val prompt = binding.etPrompt.text.toString().trim()
        val hour = binding.etHour.text.toString().padStart(2, '0')
        val minute = binding.etMinute.text.toString().padStart(2, '0')
        val cron = if (selectedFreq == "custom") {
            binding.etCron.text.toString().trim()
        } else {
            getCronExpression(selectedFreq, hour, minute)
        }
        
        if (name.isEmpty()) {
            Toast.makeText(this, "请输入任务名称", Toast.LENGTH_SHORT).show()
            return
        }
        if (prompt.isEmpty()) {
            Toast.makeText(this, "请输入提示词", Toast.LENGTH_SHORT).show()
            return
        }
        
        val data = mutableMapOf<String, Any>(
            "name" to name,
            "prompt" to prompt,
            "cron_expression" to cron,
            "notification_enabled" to binding.switchNotify.isChecked,
            "description" to binding.etDesc.text.toString().trim()
        )
        
        lifecycleScope.launch {
            val result = if (isEdit) {
                apiService.updateTask(taskId!!.toLong(), data)
            } else {
                apiService.createTask(data)
            }
            
            if (result?.code == 0) {
                Toast.makeText(this@TaskEditActivity, 
                    if (isEdit) "修改成功" else "创建成功", Toast.LENGTH_SHORT).show()
                finish()
            } else {
                Toast.makeText(this@TaskEditActivity, 
                    if (isEdit) "修改失败" else "创建失败", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun getCronExpression(freq: String, hour: String, minute: String): String {
        return when (freq) {
            "daily" -> "0 ${hour} * * *"
            "weekly" -> "0 ${hour} * * 1"
            "friday" -> "0 ${hour} * * 5"
            "monthly" -> "0 ${hour} 1 * *"
            else -> "0 ${hour} * * *"
        }
    }
}
