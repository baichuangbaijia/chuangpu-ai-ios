package com.chuangpu.ai.ui.chat

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.GridView
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.ActivityFilePickerBinding
import com.chuangpu.ai.network.ApiService
import com.chuangpu.ai.util.PreferencesManager
import com.chuangpu.ai.database.ChatDatabase
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

class FilePickerActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_SELECTED_URIS = "selected_uris"
        const val REQUEST_SYSTEM_FILE = 3001
    }

    private lateinit var binding: ActivityFilePickerBinding
    private lateinit var apiService: ApiService
    private lateinit var prefs: PreferencesManager
    private lateinit var chatDb: ChatDatabase
    private val selectedFiles = mutableListOf<FileItem>()
    private val allItems = mutableListOf<FileItem>()
    private var currentTab = "聊天"
    private val tabs = listOf("聊天", "收藏", "手机相册", "手机文件")
    private val tabButtons = mutableListOf<TextView>()

    data class FileItem(
        val uri: String,
        val name: String,
        val size: Long,
        val date: Long,
        val mimeType: String,
        val category: String,
        val source: String
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityFilePickerBinding.inflate(layoutInflater)
        setContentView(binding.root)
        apiService = ApiService(this)
        prefs = PreferencesManager.getInstance(this)
        chatDb = ChatDatabase(this)
        binding.btnBack.setOnClickListener { finish() }
        binding.btnConfirm.setOnClickListener { returnResult() }
        setupTabs()
        loadForTab()
    }

    private fun setupTabs() {
        for (tab in tabs) {
            val tv = TextView(this).apply {
                text = tab
                setTextColor(if (tab == currentTab) 0xFF7C3AED.toInt() else 0xFF6B7280.toInt())
                textSize = 15f
                setPadding(20, 6, 20, 6)
                gravity = Gravity.CENTER
                setOnClickListener { switchTab(tab) }
            }
            val lp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
            binding.tabContainer.addView(tv, lp)
            tabButtons.add(tv)
        }
    }

    private fun switchTab(tab: String) {
        currentTab = tab
        tabButtons.forEachIndexed { i, tv ->
            tv.setTextColor(if (tabs[i] == tab) 0xFF7C3AED.toInt() else 0xFF6B7280.toInt())
        }
        loadForTab()
    }



    private fun loadForTab() {
        binding.loadingView.visibility = View.GONE
        binding.rvFiles.visibility = View.GONE
        binding.emptyView.visibility = View.GONE
        hideCategoryGrid()
        when (currentTab) {
            "聊天" -> loadChatFiles()
            "收藏" -> loadFavoriteFiles()
            "手机相册" -> loadAlbumFiles()
            "手机文件" -> showPhoneFileCategories()
        }
    }

    private fun hideCategoryGrid() {
        (binding.emptyView.parent as? ViewGroup)?.findViewWithTag<View>("catGrid")?.let {
            it.visibility = View.GONE
        }
    }

    private fun showPhoneFileCategories() {
        val parent = binding.emptyView.parent as ViewGroup
        // Remove old grid if any
        parent.findViewWithTag<View>("catGrid")?.let { parent.removeView(it) }
        val categories = listOf(
            Triple("📄", "文档", arrayOf("application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "text/plain", "text/csv")),
            Triple("🖼️", "图片", arrayOf("image/*")),
            Triple("🎬", "视频", arrayOf("video/*")),
            Triple("🎵", "音频", arrayOf("audio/*")),
            Triple("📦", "压缩包", arrayOf("application/zip", "application/x-rar-compressed")),
            Triple("📂", "全部", arrayOf("*/*"))
        )
        val grid = LinearLayout(this).apply {
            tag = "catGrid"
            orientation = LinearLayout.VERTICAL
            setPadding(24, 32, 24, 32)
            val row1 = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL; layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT) }
            val row2 = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL; layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT) }
            categories.forEachIndexed { index, (icon, name, mimes) ->
                val itemView = LayoutInflater.from(context).inflate(R.layout.item_phone_file_category, null)
                itemView.findViewById<TextView>(R.id.catIcon).text = icon
                itemView.findViewById<TextView>(R.id.catName).text = name
                itemView.layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                itemView.setOnClickListener { openSystemFilePicker(mimes) }
                if (index < 3) row1.addView(itemView) else row2.addView(itemView)
            }
            addView(row1)
            addView(row2)
            val tip = TextView(context).apply {
                text = "从手机中选取文件"
                setTextColor(0xFF6B7280.toInt())
                textSize = 13f
                gravity = Gravity.CENTER
                setPadding(0, 24, 0, 0)
            }
            addView(tip)
        }
        val idx = parent.indexOfChild(binding.emptyView)
        parent.addView(grid, idx)
        grid.visibility = View.VISIBLE
    }

    private fun openSystemFilePicker(mimeTypes: Array<String>) {
        val isAll = mimeTypes.contentEquals(arrayOf("*/*"))
        val intent = if (isAll) {
            // 全部：用ACTION_GET_CONTENT弹出应用选择器（文件管理器、WPS等），内容更全面
            Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "*/*"
                addCategory(Intent.CATEGORY_OPENABLE)
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
        } else {
            // 其他分类：用ACTION_OPEN_DOCUMENT打开系统文档选择器
            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                type = "*/*"
                addCategory(Intent.CATEGORY_OPENABLE)
                putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
        }
        startActivityForResult(intent, REQUEST_SYSTEM_FILE)
    }

    private fun loadChatFiles() {
        allItems.clear()
        try {
            // 直接从本地数据库读取，秒出
            val msgs = chatDb.getAllFileMessages()
            for (msg in msgs) {
                val content = msg.content
                val urlPattern = Regex("""https?://[^\s)"'<>]+\.(pdf|docx?|xlsx?|pptx?|zip|rar|7z|gz|tar|txt|csv|jpg|jpeg|png|gif|mp4)""", RegexOption.IGNORE_CASE)
                urlPattern.findAll(content).forEach { match ->
                    val url = match.value
                    val ext = match.groupValues[1].lowercase()
                    val fname = url.substringAfterLast("/")
                    if (!allItems.any { it.uri == url }) {
                        allItems.add(FileItem(uri = url, name = fname, size = 0, date = msg.createdAt, mimeType = extToMime(ext), category = extToCategory(ext), source = "来自聊天"))
                    }
                }
                val tagPattern = Regex("""\[文件:([^\]]+)\]""")
                tagPattern.findAll(content).forEach { match ->
                    val fname = match.groupValues[1]
                    val ext = fname.substringAfterLast(".").lowercase()
                    if (!allItems.any { it.name == fname }) {
                        allItems.add(FileItem(uri = "", name = fname, size = 0, date = msg.createdAt, mimeType = extToMime(ext), category = extToCategory(ext), source = "来自聊天"))
                    }
                }
            }
        } catch (e: Exception) { e.printStackTrace() }
        showFiles()
    }

    private fun loadFavoriteFiles() {
        allItems.clear()
        showFiles()
    }

    private fun loadAlbumFiles() {
        allItems.clear()
        try {
            val imgProjection = arrayOf(android.provider.MediaStore.Images.Media._ID, android.provider.MediaStore.Images.Media.DISPLAY_NAME, android.provider.MediaStore.Images.Media.SIZE, android.provider.MediaStore.Images.Media.DATE_MODIFIED)
            val imgCursor = contentResolver.query(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, imgProjection, null, null, android.provider.MediaStore.Images.Media.DATE_MODIFIED + " DESC LIMIT 100")
            imgCursor?.use {
                val idCol = it.getColumnIndexOrThrow(android.provider.MediaStore.Images.Media._ID)
                val nameCol = it.getColumnIndexOrThrow(android.provider.MediaStore.Images.Media.DISPLAY_NAME)
                val sizeCol = it.getColumnIndexOrThrow(android.provider.MediaStore.Images.Media.SIZE)
                val dateCol = it.getColumnIndexOrThrow(android.provider.MediaStore.Images.Media.DATE_MODIFIED)
                while (it.moveToNext()) {
                    val id = it.getLong(idCol)
                    val uri = Uri.withAppendedPath(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id.toString())
                    allItems.add(FileItem(uri = uri.toString(), name = it.getString(nameCol) ?: "图片", size = it.getLong(sizeCol), date = it.getLong(dateCol) * 1000, mimeType = "image/*", category = "图片", source = "手机相册"))
                }
            }
            val vidProjection = arrayOf(android.provider.MediaStore.Video.Media._ID, android.provider.MediaStore.Video.Media.DISPLAY_NAME, android.provider.MediaStore.Video.Media.SIZE, android.provider.MediaStore.Video.Media.DATE_MODIFIED)
            val vidCursor = contentResolver.query(android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI, vidProjection, null, null, android.provider.MediaStore.Video.Media.DATE_MODIFIED + " DESC LIMIT 50")
            vidCursor?.use {
                val idCol = it.getColumnIndexOrThrow(android.provider.MediaStore.Video.Media._ID)
                val nameCol = it.getColumnIndexOrThrow(android.provider.MediaStore.Video.Media.DISPLAY_NAME)
                val sizeCol = it.getColumnIndexOrThrow(android.provider.MediaStore.Video.Media.SIZE)
                val dateCol = it.getColumnIndexOrThrow(android.provider.MediaStore.Video.Media.DATE_MODIFIED)
                while (it.moveToNext()) {
                    val id = it.getLong(idCol)
                    val uri = Uri.withAppendedPath(android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id.toString())
                    allItems.add(FileItem(uri = uri.toString(), name = it.getString(nameCol) ?: "视频", size = it.getLong(sizeCol), date = it.getLong(dateCol) * 1000, mimeType = "video/*", category = "视频", source = "手机相册"))
                }
            }
        } catch (e: Exception) { e.printStackTrace() }
        showFiles()
    }

    private fun showFiles() {
        binding.loadingView.visibility = View.GONE
        hideCategoryGrid()
        if (allItems.isEmpty()) {
            binding.emptyView.visibility = View.VISIBLE
            binding.rvFiles.visibility = View.GONE
        } else {
            binding.emptyView.visibility = View.GONE
            binding.rvFiles.visibility = View.VISIBLE
            binding.rvFiles.layoutManager = LinearLayoutManager(this)
            binding.rvFiles.adapter = FileAdapter(allItems)
        }
    }

    private fun returnResult() {
        val uris = selectedFiles.map { it.uri }.toTypedArray()
        val intent = Intent().apply {
            putExtra(EXTRA_SELECTED_URIS, uris)
        }
        setResult(Activity.RESULT_OK, intent)
        finish()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_SYSTEM_FILE && resultCode == Activity.RESULT_OK) {
            // 把系统选择器返回的URI统一转成EXTRA_SELECTED_URIS格式
            val uris = mutableListOf<String>()
            // 优先用clipData（多选时），单选时data和clipData可能重复，只取一个
            data?.clipData?.let { clip ->
                for (i in 0 until clip.itemCount) {
                    uris.add(clip.getItemAt(i).uri.toString())
                }
            }
            if (uris.isEmpty()) {
                data?.data?.let { uris.add(it.toString()) }
            }
            val resultIntent = Intent().apply {
                putExtra(EXTRA_SELECTED_URIS, uris.toTypedArray())
            }
            setResult(Activity.RESULT_OK, resultIntent)
            finish()
        }
    }

    private fun extToMime(ext: String): String = when (ext) {
        "pdf" -> "application/pdf"
        "doc", "docx" -> "application/msword"
        "xls", "xlsx" -> "application/vnd.ms-excel"
        "zip" -> "application/zip"
        "rar" -> "application/x-rar-compressed"
        "txt" -> "text/plain"
        "csv" -> "text/csv"
        else -> "application/octet-stream"
    }

    private fun extToCategory(ext: String): String = when (ext) {
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "csv" -> "文档"
        "zip", "rar", "7z", "gz", "tar" -> "压缩包"
        "jpg", "jpeg", "png", "gif", "webp" -> "图片"
        "mp4", "avi", "mkv", "mov" -> "视频"
        else -> "其他"
    }

    private fun getFileIcon(item: FileItem): String = when (item.category) {
        "图片" -> "🖼️"
        "视频" -> "🎬"
        "压缩包" -> "📦"
        "文档" -> when {
            item.name.endsWith(".pdf") -> "📕"
            item.name.endsWith(".doc") || item.name.endsWith(".docx") -> "📘"
            item.name.endsWith(".xls") || item.name.endsWith(".xlsx") -> "📗"
            item.name.endsWith(".ppt") || item.name.endsWith(".pptx") -> "📙"
            else -> "📄"
        }
        else -> "📄"
    }

    private fun formatSize(size: Long): String = when {
        size <= 0 -> ""
        size < 1024 -> "$size B"
        size < 1024 * 1024 -> "%.1fKB".format(size / 1024.0)
        else -> "%.1fMB".format(size / (1024.0 * 1024.0))
    }

    private fun formatDate(ts: Long): String {
        if (ts <= 0) return ""
        val now = System.currentTimeMillis()
        val diff = now - ts
        return when {
            diff < 86400000 -> "今天 " + SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(ts))
            diff < 172800000 -> "昨天"
            diff < 604800000 -> "${(diff / 86400000).toInt()}天前"
            else -> SimpleDateFormat("MM/dd", Locale.getDefault()).format(Date(ts))
        }
    }

    inner class FileAdapter(private val items: List<FileItem>) : RecyclerView.Adapter<FileAdapter.VH>() {
        inner class VH(view: View) : RecyclerView.ViewHolder(view) {
            val icon: TextView = view.findViewById(R.id.fileIcon)
            val name: TextView = view.findViewById(R.id.fileName)
            val meta: TextView = view.findViewById(R.id.fileMeta)
            val check: CheckBox = view.findViewById(R.id.fileCheck)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) =
            VH(LayoutInflater.from(parent.context).inflate(R.layout.item_file_picker, parent, false))

        override fun onBindViewHolder(holder: VH, position: Int) {
            val item = items[position]
            holder.icon.text = getFileIcon(item)
            holder.name.text = item.name
            val sizeStr = formatSize(item.size)
            val dateStr = formatDate(item.date)
            holder.meta.text = listOfNotNull(sizeStr, item.source, dateStr.ifEmpty { null }).joinToString(" · ")
            holder.check.isChecked = selectedFiles.any { it.uri == item.uri }
            holder.check.setOnCheckedChangeListener(null)
            val toggle = {
                val idx = selectedFiles.indexOfFirst { it.uri == item.uri }
                if (idx >= 0) {
                    selectedFiles.removeAt(idx)
                    holder.check.isChecked = false
                } else {
                    selectedFiles.add(item)
                    holder.check.isChecked = true
                }
                binding.btnConfirm.text = "发送(${selectedFiles.size})"
            }
            holder.itemView.setOnClickListener { toggle() }
            holder.check.setOnClickListener { toggle() }
        }

        override fun getItemCount() = items.size
    }
}
