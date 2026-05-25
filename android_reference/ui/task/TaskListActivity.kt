package com.chuangpu.ai.ui.task

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.ActivityTaskListBinding
import com.chuangpu.ai.model.Task
import com.chuangpu.ai.network.ApiService
import com.chuangpu.ai.util.CronParser
import kotlinx.coroutines.launch

class TaskListActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityTaskListBinding
    private lateinit var apiService: ApiService
    private lateinit var adapter: TaskAdapter
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityTaskListBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        apiService = ApiService(this)
        
        setupUI()
        loadTasks()
    }
    
    private fun setupUI() {
        binding.btnBack.setOnClickListener { finish() }
        binding.btnAdd.setOnClickListener {
            startActivity(Intent(this, TaskEditActivity::class.java))
        }
        
        adapter = TaskAdapter(
            onToggle = { task -> toggleTask(task) },
            onEdit = { task -> editTask(task) },
            onDelete = { task -> deleteTask(task) }
        )
        binding.rvTasks.layoutManager = LinearLayoutManager(this)
        binding.rvTasks.adapter = adapter
    }
    
    override fun onResume() {
        super.onResume()
        loadTasks()
    }
    
    private fun loadTasks() {
        binding.progressBar.visibility = View.VISIBLE
        
        lifecycleScope.launch {
            val result = apiService.getTaskList()
            binding.progressBar.visibility = View.GONE
            
            if (result?.code == 0) {
                val list = result.data?.list ?: emptyList()
                adapter.submitList(list)
                
                if (list.isEmpty()) {
                    binding.emptyState.visibility = View.VISIBLE
                    binding.rvTasks.visibility = View.GONE
                } else {
                    binding.emptyState.visibility = View.GONE
                    binding.rvTasks.visibility = View.VISIBLE
                }
            } else {
                binding.emptyState.visibility = View.VISIBLE
            }
        }
    }
    
    private fun toggleTask(task: Task) {
        lifecycleScope.launch {
            val result = if (task.status == "active") {
                apiService.pauseTask(task.id.toLong())
            } else {
                apiService.resumeTask(task.id.toLong())
            }
            
            if (result?.code == 0) {
                Toast.makeText(this@TaskListActivity, 
                    if (task.status == "active") "任务已暂停" else "任务已启用", 
                    Toast.LENGTH_SHORT).show()
                loadTasks()
            } else {
                Toast.makeText(this@TaskListActivity, "操作失败", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun editTask(task: Task) {
        startActivity(Intent(this, TaskEditActivity::class.java).apply {
            putExtra("taskId", task.id.toLong())
        })
    }
    
    private fun deleteTask(task: Task) {
        AlertDialog.Builder(this)
            .setTitle("删除任务")
            .setMessage("确定要删除任务「${task.name}」吗？")
            .setPositiveButton("删除") { _, _ ->
                lifecycleScope.launch {
                    val result = apiService.deleteTask(task.id.toLong())
                    if (result?.code == 0) {
                        Toast.makeText(this@TaskListActivity, "删除成功", Toast.LENGTH_SHORT).show()
                        loadTasks()
                    } else {
                        Toast.makeText(this@TaskListActivity, "删除失败", Toast.LENGTH_SHORT).show()
                    }
                }
            }
            .setNegativeButton("取消", null)
            .show()
    }
}

class TaskAdapter(
    private val onToggle: (Task) -> Unit,
    private val onEdit: (Task) -> Unit,
    private val onDelete: (Task) -> Unit
) : RecyclerView.Adapter<TaskAdapter.ViewHolder>() {
    
    private var items = listOf<Task>()
    
    fun submitList(list: List<Task>) {
        items = list
        notifyDataSetChanged()
    }
    
    override fun onCreateViewHolder(parent: android.view.ViewGroup, viewType: Int): ViewHolder {
        val view = android.view.LayoutInflater.from(parent.context)
            .inflate(R.layout.item_task, parent, false)
        return ViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }
    
    override fun getItemCount() = items.size
    
    inner class ViewHolder(itemView: android.view.View) : RecyclerView.ViewHolder(itemView) {
        fun bind(task: Task) {
            itemView.findViewById<android.widget.TextView>(R.id.tvName).text = task.name
            itemView.findViewById<android.widget.TextView>(R.id.tvPrompt).text = task.prompt
            itemView.findViewById<android.widget.TextView>(R.id.tvCron).text = CronParser.parse(task.cron_expression)
            itemView.findViewById<android.widget.TextView>(R.id.tvRunCount).text = "${task.run_count}次"
            
            val switch = itemView.findViewById<android.widget.Switch>(R.id.switchStatus)
            switch.isChecked = task.status == "active"
            switch.setOnCheckedChangeListener { _, _ -> onToggle(task) }
            
            itemView.setOnClickListener { onEdit(task) }
            itemView.findViewById<View>(R.id.btnDelete).setOnClickListener { onDelete(task) }
        }
    }
}
