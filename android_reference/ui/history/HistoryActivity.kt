package com.chuangpu.ai.ui.history

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.ActivityHistoryBinding
import com.chuangpu.ai.model.Conversation
import com.chuangpu.ai.network.ApiService
import com.chuangpu.ai.ui.chat.ChatActivity
import kotlinx.coroutines.launch

class HistoryActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityHistoryBinding
    private lateinit var apiService: ApiService
    private lateinit var adapter: HistoryAdapter
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityHistoryBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        apiService = ApiService(this)
        
        setupUI()
        loadHistory()
    }
    
    private fun setupUI() {
        binding.btnBack.setOnClickListener { finish() }
        
        adapter = HistoryAdapter { conversation ->
            val sid = conversation.session_id.ifEmpty { conversation.model }
            startActivity(Intent(this, ChatActivity::class.java).apply {
                putExtra("session_id", sid)
            })
            finish()
        }
        binding.rvHistory.layoutManager = LinearLayoutManager(this)
        binding.rvHistory.adapter = adapter
    }
    
    private fun loadHistory() {
        binding.progressBar.visibility = View.VISIBLE
        
        lifecycleScope.launch {
            val result = apiService.getConversations()
            binding.progressBar.visibility = View.GONE
            
            if (result?.code == 0) {
                val list = result.data?.list ?: emptyList()
                adapter.submitList(list)
                
                if (list.isEmpty()) {
                    binding.emptyState.visibility = View.VISIBLE
                    binding.rvHistory.visibility = View.GONE
                } else {
                    binding.emptyState.visibility = View.GONE
                    binding.rvHistory.visibility = View.VISIBLE
                }
            } else {
                binding.emptyState.visibility = View.VISIBLE
            }
        }
    }
}

class HistoryAdapter(
    private val onItemClick: (Conversation) -> Unit
) : RecyclerView.Adapter<HistoryAdapter.ViewHolder>() {
    
    private var items = listOf<Conversation>()
    
    fun submitList(list: List<Conversation>) {
        items = list
        notifyDataSetChanged()
    }
    
    override fun onCreateViewHolder(parent: android.view.ViewGroup, viewType: Int): ViewHolder {
        val view = android.view.LayoutInflater.from(parent.context)
            .inflate(R.layout.item_history, parent, false)
        return ViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }
    
    override fun getItemCount() = items.size
    
    private fun formatRelativeTime(timestamp: String?): String {
        if (timestamp.isNullOrEmpty()) return ""
        try {
            val sdf = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault())
            val date = sdf.parse(timestamp) ?: return timestamp
            val diff = System.currentTimeMillis() - date.time
            return when {
                diff < 60000 -> "刚刚"
                diff < 3600000 -> "${diff / 60000}分钟前"
                diff < 86400000 -> "${diff / 3600000}小时前"
                diff < 604800000 -> "${diff / 86400000}天前"
                else -> {
                    val showSdf = java.text.SimpleDateFormat("MM/dd HH:mm", java.util.Locale.getDefault())
                    showSdf.format(date)
                }
            }
        } catch (e: Exception) { return timestamp }
    }

    inner class ViewHolder(itemView: android.view.View) : RecyclerView.ViewHolder(itemView) {
        fun bind(conv: Conversation) {
            itemView.findViewById<android.widget.TextView>(R.id.tvTitle).text = conv.title.ifEmpty { "新对话" }
            itemView.findViewById<android.widget.TextView>(R.id.tvTime).text = formatRelativeTime(conv.updated_at ?: conv.created_at)
            itemView.setOnClickListener { onItemClick(conv) }
        }
    }
}
