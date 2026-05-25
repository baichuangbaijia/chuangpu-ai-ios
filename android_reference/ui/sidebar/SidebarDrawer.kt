package com.chuangpu.ai.ui.sidebar

import android.app.Dialog
import android.text.Editable
import android.text.TextUtils
import android.text.TextWatcher
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.Window
import android.view.WindowManager
import android.widget.*
import androidx.lifecycle.lifecycleScope
import com.chuangpu.ai.R
import com.chuangpu.ai.model.Conversation
import com.chuangpu.ai.model.Subtask
import com.chuangpu.ai.network.ApiService
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

// 对照Vue: Sidebar.vue - 完整侧边栏
class SidebarDrawer(
    private val context: Context,
    private val currentConversationId: String?,
    private val onConversationSelected: (Conversation) -> Unit
) {

    private val dialog = Dialog(context)
    private val apiService = ApiService(context)
    private val conversations = mutableListOf<Conversation>()
    private var filteredConversations = mutableListOf<Conversation>()
    private var searchText = ""

    // 对照Vue: 子任务轮询
    private var subtasks = listOf<Subtask>()
    private var subtaskPollingTimer: Handler? = null
    private var subtaskRunnable: Runnable? = null

    init {
        setupDialog()
    }

    private fun setupDialog() {
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
        dialog.setContentView(R.layout.view_sidebar)
        dialog.window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        dialog.window?.setLayout(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT
        )
        dialog.setCanceledOnTouchOutside(false)

        // 对照Vue: sb-overlay @click="$emit(close)" 点击遮罩关闭
        dialog.findViewById<View>(R.id.sidebarDismissArea)?.setOnClickListener {
            dismiss()
        }

        // 对照Vue: sb-search 搜索框
        val etSearch = dialog.findViewById<EditText>(R.id.etSearchSidebar)
        etSearch?.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                searchText = s.toString().trim()
                filterAndDisplay()
            }
        })

        // 对照Vue: sb-wechat 微信消息入口
        dialog.findViewById<View>(R.id.btnWechat)?.setOnClickListener {
            Toast.makeText(context, "功能开发中", Toast.LENGTH_SHORT).show()
        }
    }

    fun show() {
        fetchConversations()
        startSubtaskPolling()
        dialog.show()
    }

    fun dismiss() {
        stopSubtaskPolling()
        dialog.dismiss()
    }

    // 对照Vue: fetchConversations - 拉取真实会话列表
    private fun fetchConversations() {
        (context as? androidx.lifecycle.LifecycleOwner)?.lifecycleScope?.launch {
            try {
                val result = apiService.getConversations()
                conversations.clear()
                // 对照Vue: const list = data.data || data || []
                // /agent/api 返回 data 直接是 list
                val list = result?.data?.list ?: emptyList()
                conversations.addAll(list)
                filterAndDisplay()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    // 对照Vue: filteredConversations computed
    private fun filterAndDisplay() {
        filteredConversations = if (searchText.isEmpty()) {
            conversations.toMutableList()
        } else {
            conversations.filter { it.title.contains(searchText, ignoreCase = true) }.toMutableList()
        }
        updateConversationList()
    }

    // 对照竞品和网页端：按日期细粒度分组 (今天/昨天/2天前/.../X月X日)
    private fun updateConversationList() {
        val container = dialog.findViewById<LinearLayout>(R.id.conversationList)
        container?.removeAllViews()

        // 按日期分组
        val groupMap = linkedMapOf<String, MutableList<Conversation>>()
        for (conv in filteredConversations) {
            val label = getGroupLabel(conv.updated_at)
            if (!groupMap.containsKey(label)) groupMap[label] = mutableListOf()
            groupMap[label]!!.add(conv)
        }

        // 按分组顺序渲染
        var isFirst = true
        for ((label, items) in groupMap) {
            val hint = if (isFirst) "长按记录可编辑或删除" else null
            addGroup(container, label, hint, items)
            isFirst = false
        }

        // 对照Vue: sb-empty "暂无对话记录"
        if (groupMap.isEmpty()) {
            val emptyView = TextView(context).apply {
                text = "暂无对话记录"
                setTextColor(Color.parseColor("#4DFFFFFF"))
                textSize = 14f
                setPadding(0, 80, 0, 0)
                gravity = Gravity.CENTER
            }
            container?.addView(emptyView)
        }
    }

    // 对照竞品：今天/昨天/X天前/X月X日
    private fun getGroupLabel(dateStr: String?): String {
        if (dateStr.isNullOrEmpty()) return "更早"
        return try {
            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
            val date = sdf.parse(dateStr) ?: return "更早"
            val cal = Calendar.getInstance()
            val today = Calendar.getInstance()
            cal.time = date
            // 清除时分秒用于日期比较
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            today.set(Calendar.HOUR_OF_DAY, 0)
            today.set(Calendar.MINUTE, 0)
            today.set(Calendar.SECOND, 0)
            today.set(Calendar.MILLISECOND, 0)
            val diffDays = ((today.timeInMillis - cal.timeInMillis) / (1000 * 60 * 60 * 24)).toInt()
            when {
                diffDays == 0 -> "今天"
                diffDays == 1 -> "昨天"
                diffDays in 2..6 -> "${diffDays}天前"
                diffDays in 7..30 -> "${diffDays / 7}周前"
                else -> {
                    val mFormat = SimpleDateFormat("M月d日", Locale.getDefault())
                    mFormat.format(date)
                }
            }
        } catch (e: Exception) { "更早" }
    }

    // 对照Vue: sb-group + sb-conv
    private fun addGroup(parent: LinearLayout?, label: String, hint: String?, items: List<Conversation>) {
        parent ?: return

        // 对照Vue: sb-group-label { color: rgba(255,255,255,.4); font-size: 12px; margin-bottom: 6px; }
        val labelView = TextView(context).apply {
            text = label
            setTextColor(Color.parseColor("#66FFFFFF"))
            textSize = 12f
            setPadding(0, 16, 0, 6)
        }
        parent.addView(labelView)

        // 对照Vue: sb-group-hint { color: rgba(255,255,255,.25); font-size: 11px; margin-bottom: 8px; }
        if (!hint.isNullOrEmpty()) {
            val hintView = TextView(context).apply {
                text = hint
                setTextColor(Color.parseColor("#40FFFFFF"))
                textSize = 11f
                setPadding(0, 0, 0, 8)
            }
            parent.addView(hintView)
        }

        // 对照竞品：会话条目 - 更亮背景 + 右侧状态标签
        items.forEach { conv ->
            val itemView = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(24, 20, 24, 20)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { setMargins(0, 0, 0, 8) }
                // 更亮的背景 rgba(255,255,255,0.06)
                setBackgroundColor(Color.parseColor("#0FFFFFFF"))

                // 标题
                val titleView = TextView(context).apply {
                    text = conv.title.ifEmpty { "新对话" }
                    setTextColor(Color.parseColor("#E6FFFFFF"))
                    textSize = 15f
                    layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                    maxLines = 1
                    ellipsize = TextUtils.TruncateAt.END
                }
                addView(titleView)

                // 对照竞品：右侧"已完成"状态标签
                val statusView = TextView(context).apply {
                    text = "已完成"
                    setTextColor(Color.parseColor("#4ADE80"))
                    textSize = 12f
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    )
                    setPadding(8, 2, 8, 2)
                }
                addView(statusView)

                // 对照Vue: @click="$emit(select-chat, conv)"
                setOnClickListener {
                    dismiss()
                    onConversationSelected(conv)
                }

                // 对照Vue: 长按删除
                setOnLongClickListener {
                    showDeleteConfirm(conv)
                    true
                }
            }
            parent.addView(itemView)
        }
    }

    // 对照Vue: showConfirmDialog 删除确认
    private fun showDeleteConfirm(conv: Conversation) {
        android.app.AlertDialog.Builder(context)
            .setTitle("删除对话")
            .setMessage("确定删除这条对话记录吗？")
            .setPositiveButton("删除") { _, _ ->
                deleteConversation(conv)
            }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun deleteConversation(conv: Conversation) {
        (context as? androidx.lifecycle.LifecycleOwner)?.lifecycleScope?.launch {
            apiService.deleteConversation(conv.id)
            conversations.remove(conv)
            filterAndDisplay()
            Toast.makeText(context, "已删除", Toast.LENGTH_SHORT).show()
        }
    }

    // ===== 子任务轮询 ===== 对照Vue: fetchSubtasks + subtaskPollingTimer

    private fun startSubtaskPolling() {
        if (currentConversationId == null) return
        fetchSubtasks()
        subtaskPollingTimer = Handler(Looper.getMainLooper())
        subtaskRunnable = object : Runnable {
            override fun run() {
                fetchSubtasks()
                subtaskPollingTimer?.postDelayed(this, 2000)
            }
        }
        subtaskPollingTimer?.postDelayed(subtaskRunnable!!, 2000)
    }

    private fun stopSubtaskPolling() {
        subtaskRunnable?.let { subtaskPollingTimer?.removeCallbacks(it) }
        subtaskRunnable = null
        subtaskPollingTimer = null
    }

    // 对照Vue: fetchSubtasks
    private fun fetchSubtasks() {
        if (currentConversationId == null) return
        val convId = currentConversationId.toLongOrNull() ?: return
        (context as? androidx.lifecycle.LifecycleOwner)?.lifecycleScope?.launch {
            try {
                val result = apiService.getSubtasks(convId)
                subtasks = result?.data ?: emptyList()
                updateSubtasksUI()
            } catch (_: Exception) { }
        }
    }

    // 对照Vue: runningSubtasks + completedSubtasks分组显示
    private fun updateSubtasksUI() {
        val subtaskContainer = dialog.findViewById<LinearLayout>(R.id.subtaskContainer)
        val subtaskDivider = dialog.findViewById<View>(R.id.subtaskDivider)
        subtaskContainer?.removeAllViews()

        if (subtasks.isEmpty()) {
            subtaskContainer?.visibility = View.GONE
            subtaskDivider?.visibility = View.GONE
            return
        }

        subtaskContainer?.visibility = View.VISIBLE
        subtaskDivider?.visibility = View.VISIBLE

        // 对照Vue: sb-subtasks-title
        val titleView = TextView(context).apply {
            text = "📋 子任务"
            setTextColor(Color.WHITE)
            textSize = 14f
            setPadding(0, 0, 0, 10)
        }
        subtaskContainer?.addView(titleView)

        // 对照Vue: 运行中 sb-subtasks-group
        val running = subtasks.filter { it.status == "running" }
        if (running.isNotEmpty()) {
            val label = TextView(context).apply {
                text = "🔄 运行中"
                setTextColor(Color.parseColor("#80FFFFFF"))
                textSize = 11f
                setPadding(0, 4, 0, 4)
            }
            subtaskContainer?.addView(label)
            running.forEach { task ->
                subtaskContainer?.addView(createSubtaskItem(task, false))
            }
        }

        // 对照Vue: 已完成 sb-subtasks-group
        val completed = subtasks.filter { it.status == "completed" }
        if (completed.isNotEmpty()) {
            val label = TextView(context).apply {
                text = "✅ 已完成"
                setTextColor(Color.parseColor("#80FFFFFF"))
                textSize = 11f
                setPadding(0, 8, 0, 4)
            }
            subtaskContainer?.addView(label)
            completed.forEach { task ->
                subtaskContainer?.addView(createSubtaskItem(task, true))
            }
        }
    }

    private fun createSubtaskItem(task: Subtask, isCompleted: Boolean): View {
        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(8, 6, 8, 6)
            setBackgroundResource(R.drawable.bg_sidebar_item)

            val nameView = TextView(context).apply {
                text = task.name
                setTextColor(if (isCompleted) Color.parseColor("#B3FFFFFF") else Color.WHITE)
                textSize = 13f
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
            }
            addView(nameView)

            if (isCompleted) {
                val checkView = TextView(context).apply {
                    text = "✓"
                    setTextColor(Color.parseColor("#4ADE80"))
                    textSize = 12f
                }
                addView(checkView)
            } else {
                val timeView = TextView(context).apply {
                    text = formatTime(task.created_at)
                    setTextColor(Color.parseColor("#66FFFFFF"))
                    textSize = 11f
                }
                addView(timeView)
            }
        }
    }

    // 对照Vue: formatTime
    private fun formatTime(dateStr: String?): String {
        if (dateStr.isNullOrEmpty()) return ""
        return try {
            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
            val date = sdf.parse(dateStr)
            val diff = (Date().time - (date?.time ?: 0)) / 1000
            when {
                diff < 60 -> "${diff.toInt()}秒前"
                diff < 3600 -> "${(diff / 60).toInt()}分钟前"
                else -> "${(diff / 3600).toInt()}小时前"
            }
        } catch (e: Exception) { "" }
    }
}
