package com.chuangpu.ai.ui.memory

import android.app.AlertDialog
import android.os.Bundle
import android.view.View
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.ActivityMemoryBinding
import com.chuangpu.ai.model.Memory
import com.chuangpu.ai.network.ApiService
import kotlinx.coroutines.launch

class MemoryActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMemoryBinding
    private lateinit var apiService: ApiService
    private lateinit var adapter: MemoryAdapter
    
    private var currentPage = 1
    private val pageSize = 20
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMemoryBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        apiService = ApiService(this)
        
        setupUI()
        loadMemories()
    }
    
    private fun setupUI() {
        binding.btnBack.setOnClickListener { finish() }
        
        adapter = MemoryAdapter(
            onView = { memory -> showDetail(memory) },
            onEdit = { memory -> editMemory(memory) },
            onDelete = { memory -> deleteMemory(memory.id) }
        )
        binding.rvMemory.layoutManager = LinearLayoutManager(this)
        binding.rvMemory.adapter = adapter
        
        binding.etSearch.setOnEditorActionListener { _, _, _ ->
            loadMemories()
            true
        }
    }
    
    private fun loadMemories(page: Int = 1) {
        binding.progressBar.visibility = View.VISIBLE
        
        lifecycleScope.launch {
            val keyword = binding.etSearch.text.toString().trim()
            val result = apiService.getMemoryList(page, pageSize, keyword.ifEmpty { "" })
            binding.progressBar.visibility = View.GONE
            
            if (result?.code == 0) {
                val list = result.data?.list ?: emptyList()
                adapter.submitList(list)
                
                if (list.isEmpty()) {
                    binding.emptyState.visibility = View.VISIBLE
                } else {
                    binding.emptyState.visibility = View.GONE
                }
            } else {
                binding.emptyState.visibility = View.VISIBLE
            }
        }
    }
    
    private fun showDetail(memory: Memory) {
        AlertDialog.Builder(this)
            .setTitle("记忆详情")
            .setMessage(memory.content)
            .setPositiveButton("编辑") { _, _ -> editMemory(memory) }
            .setNegativeButton("关闭", null)
            .show()
    }
    
    private fun editMemory(memory: Memory) {
        val editText = EditText(this).apply {
            setText(memory.content)
            hint = "请输入记忆内容"
        }
        
        AlertDialog.Builder(this)
            .setTitle("编辑记忆")
            .setView(editText)
            .setPositiveButton("保存") { _, _ ->
                val newContent = editText.text.toString().trim()
                if (newContent.isNotEmpty()) {
                    updateMemory(memory.id, newContent)
                }
            }
            .setNegativeButton("取消", null)
            .show()
    }
    
    private fun updateMemory(id: String, content: String) {
        lifecycleScope.launch {
            val result = apiService.updateMemory(id, content)
            if (result?.code == 0) {
                Toast.makeText(this@MemoryActivity, "保存成功", Toast.LENGTH_SHORT).show()
                loadMemories()
            } else {
                Toast.makeText(this@MemoryActivity, "保存失败", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun deleteMemory(id: String) {
        AlertDialog.Builder(this)
            .setTitle("确认删除")
            .setMessage("确定要删除这条记忆吗？删除后AI将不再记住这条内容。")
            .setPositiveButton("删除") { _, _ ->
                lifecycleScope.launch {
                    val result = apiService.deleteMemory(id)
                    if (result?.code == 0) {
                        Toast.makeText(this@MemoryActivity, "删除成功", Toast.LENGTH_SHORT).show()
                        loadMemories()
                    } else {
                        Toast.makeText(this@MemoryActivity, "删除失败", Toast.LENGTH_SHORT).show()
                    }
                }
            }
            .setNegativeButton("取消", null)
            .show()
    }
}

class MemoryAdapter(
    private val onView: (Memory) -> Unit,
    private val onEdit: (Memory) -> Unit,
    private val onDelete: (Memory) -> Unit
) : RecyclerView.Adapter<MemoryAdapter.ViewHolder>() {
    
    private var items = listOf<Memory>()
    
    fun submitList(list: List<Memory>) {
        items = list
        notifyDataSetChanged()
    }
    
    override fun onCreateViewHolder(parent: android.view.ViewGroup, viewType: Int): ViewHolder {
        val view = android.view.LayoutInflater.from(parent.context)
            .inflate(R.layout.item_memory, parent, false)
        return ViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }
    
    override fun getItemCount() = items.size
    
    inner class ViewHolder(itemView: android.view.View) : RecyclerView.ViewHolder(itemView) {
        fun bind(memory: Memory) {
            itemView.findViewById<android.widget.TextView>(R.id.tvContent).text = memory.content
            itemView.findViewById<android.widget.TextView>(R.id.tvTime).text = memory.created_at ?: ""
            itemView.findViewById<android.view.View>(R.id.btnView).setOnClickListener { onView(memory) }
            itemView.findViewById<android.view.View>(R.id.btnEdit).setOnClickListener { onEdit(memory) }
            itemView.findViewById<android.view.View>(R.id.btnDelete).setOnClickListener { onDelete(memory) }
        }
    }
}
