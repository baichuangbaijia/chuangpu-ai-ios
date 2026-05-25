package com.chuangpu.ai.ui.chat

import android.content.Intent
import android.net.Uri
import android.widget.ImageView
import android.os.Bundle
import android.provider.OpenableColumns
import android.os.Handler
import android.os.Looper
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import java.io.File
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.chuangpu.ai.R
import com.chuangpu.ai.databinding.ActivityChatBinding
import com.chuangpu.ai.model.Message
import com.chuangpu.ai.network.ApiService
import com.chuangpu.ai.network.ApiClient
import com.chuangpu.ai.ui.main.MainActivity
import com.chuangpu.ai.ui.sidebar.SidebarDrawer
import com.chuangpu.ai.util.PreferencesManager
import com.chuangpu.ai.util.ThemeHelper
import com.chuangpu.ai.database.ChatDatabase
import com.google.android.material.bottomsheet.BottomSheetDialog
import io.noties.markwon.Markwon
import com.bumptech.glide.Glide
import io.noties.markwon.html.HtmlPlugin
import io.noties.markwon.linkify.LinkifyPlugin
import io.noties.markwon.image.ImagesPlugin
import io.noties.markwon.image.glide.GlideImagesPlugin
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import okhttp3.Call

class ChatActivity : AppCompatActivity() {
    // V2.0.41: 连接状态管理
    private var isConnecting = false
    private val connectHandler = Handler(Looper.getMainLooper())
    private var connectPollCount = 0

    private fun checkAndCreateContainer() {
        if (isConnecting) return
        lifecycleScope.launch {
            try {
                val statusResult = apiService.getContainerStatus()
                val containerStatus = statusResult?.data?.get("container_status") as? String ?: "none"
                if (containerStatus == "running") {
                    updateConnectionUI("running")
                    return@launch
                }
                updateConnectionUI("creating")
                isConnecting = true
                val createResult = apiService.createContainer()
                if (createResult != null && createResult.code == 0) {
                    pollContainerStatus()
                } else {
                    updateConnectionUI("error")
                    isConnecting = false
                }
            } catch (e: Exception) {
                updateConnectionUI("error")
                isConnecting = false
            }
        }
    }

    private fun pollContainerStatus() {
        if (connectPollCount >= 30) {
            updateConnectionUI("error")
            isConnecting = false
            return
        }
        lifecycleScope.launch {
            try {
                val result = apiService.getContainerStatus()
                val containerStatus = result?.data?.get("container_status") as? String ?: "none"
                if (containerStatus == "running") {
                    updateConnectionUI("running")
                    isConnecting = false
                    return@launch
                } else if (containerStatus == "error") {
                    updateConnectionUI("error")
                    isConnecting = false
                    return@launch
                }
            } catch (e: Exception) {}
            connectPollCount++
            connectHandler.postDelayed({ pollContainerStatus() }, 2000)
        }
    }

    private var connectStep = 0
    private val connectStepRunnable = object : Runnable {
        override fun run() {
            if (!isConnecting) return
            connectStep++
            updateConnectOverlayStep(connectStep)
            if (connectStep < 2) {
                connectHandler.postDelayed(this, 8000)
            }
        }
    }

    private fun showConnectOverlay() {
        val overlay = findViewById<View>(R.id.connectOverlay)
        overlay?.visibility = View.VISIBLE
        connectStep = 0
        updateConnectOverlayStep(0)
        connectHandler.postDelayed(connectStepRunnable, 5000)
    }

    private fun hideConnectOverlay() {
        connectHandler.removeCallbacks(connectStepRunnable)
        val overlay = findViewById<View>(R.id.connectOverlay)
        overlay?.visibility = View.GONE
    }

    private fun updateConnectOverlayStep(step: Int) {
        val tvTitle = findViewById<TextView>(R.id.tvConnectTitle)
        val tvHint = findViewById<TextView>(R.id.tvConnectHint)
        val dot1 = findViewById<View>(R.id.dot1)
        val dot2 = findViewById<View>(R.id.dot2)
        val dot3 = findViewById<View>(R.id.dot3)

        when (step) {
            0 -> {
                tvTitle?.text = "正在连接"
                tvHint?.text = "正在分配云主机"
                dot1?.setBackgroundResource(R.drawable.bg_dot_active)
                dot2?.setBackgroundResource(R.drawable.bg_dot_inactive)
                dot3?.setBackgroundResource(R.drawable.bg_dot_inactive)
            }
            1 -> {
                tvTitle?.text = "正在连接"
                tvHint?.text = "正在安装工作环境"
                dot1?.setBackgroundResource(R.drawable.bg_dot_active)
                dot2?.setBackgroundResource(R.drawable.bg_dot_active)
                dot3?.setBackgroundResource(R.drawable.bg_dot_inactive)
            }
            2 -> {
                tvTitle?.text = "正在连接"
                tvHint?.text = "正在启动龙虾AI"
                dot1?.setBackgroundResource(R.drawable.bg_dot_active)
                dot2?.setBackgroundResource(R.drawable.bg_dot_active)
                dot3?.setBackgroundResource(R.drawable.bg_dot_active)
            }
        }
    }

    private fun updateConnectionUI(status: String) {
        val dot = findViewById<View>(R.id.statusDot)
        val tv = findViewById<TextView>(R.id.tvOnlineStatus)
        when (status) {
            "running" -> {
                dot?.setBackgroundResource(R.drawable.bg_online_dot)
                tv?.text = "在线"
                tv?.setTextColor(getColor(R.color.green_accent))
                hideConnectOverlay()
            }
            "creating" -> {
                dot?.setBackgroundResource(R.drawable.bg_gray_dot)
                tv?.text = "连接中"
                tv?.setTextColor(getColor(R.color.text_gray))
                showConnectOverlay()
            }
            else -> {
                dot?.setBackgroundResource(R.drawable.bg_gray_dot)
                tv?.text = "离线"
                tv?.setTextColor(getColor(R.color.text_gray))
            }
        }
    }

        private fun checkVipFromServer() {
        lifecycleScope.launch {
            try {
                val isVip = withContext(kotlinx.coroutines.Dispatchers.IO) {
                    val request = okhttp3.Request.Builder()
                        .url("https://ai.xianbaba188.cn/api/auth/check-vip")
                        .get()
                        .build()
                    val client = ApiClient.getClient(this@ChatActivity)
                    val response = client.newCall(request).execute()
                    response.code == 200
                }
                prefs.setIsVip(isVip)
                if (!isVip) {
                    Toast.makeText(this@ChatActivity, "请先开通会员", Toast.LENGTH_SHORT).show()
                    startActivity(Intent(this@ChatActivity, com.chuangpu.ai.ui.vip.VipActivity::class.java))
                    finish()
                    return@launch
                }
                checkAndCreateContainer()
            } catch (e: Exception) {
                android.util.Log.e("VIP_CHECK", "EXCEPTION: ${e.message}", e)
                // 网络异常不放行，安全优先
                Toast.makeText(this@ChatActivity, "网络异常，请重试", Toast.LENGTH_SHORT).show()
                startActivity(Intent(this@ChatActivity, com.chuangpu.ai.ui.vip.VipActivity::class.java))
                finish()
            }
        }
    }
    companion object {
        private const val REQUEST_CAMERA = 1001
        private const val REQUEST_ALBUM = 1002
        private const val REQUEST_FILE = 1003
        private const val REQUEST_VIDEO = 1004
    }

    private lateinit var binding: ActivityChatBinding
    private lateinit var apiService: ApiService
    private lateinit var prefs: PreferencesManager
    private lateinit var chatDb: ChatDatabase
    private lateinit var adapter: MessageAdapter
    private lateinit var markwon: Markwon

    private var sessionId: String? = null
    private var isGenerating = false
    private var currentModel = "deepseek-v3"
    private val messages = mutableListOf<Message>()
    private val messageQueue = mutableListOf<String>()
    private var currentCall: Call? = null
    private var sseTimeoutHandler: Handler? = null
    private var sseTimeoutRunnable: Runnable? = null

    enum class UploadState { IDLE, UPLOADING, SUCCESS, FAILED }
    data class PendingAttachment(
        val cachedFile: java.io.File, val fileName: String, val mimeType: String,
        val isImage: Boolean, val isVideo: Boolean, val uri: Uri,
        var uploadState: UploadState = UploadState.IDLE,
        var uploadProgress: Int = 0,  // 0-100
        var uploadedUrl: String? = null  // 上传成功后的服务器URL
    )
    private val pendingAttachments = mutableListOf<PendingAttachment>()

    private val thinkingTexts = arrayOf("小虾正在思考中...", "正在调用技能...", "正在为你创建...", "马上就好...")
    private var thinkingIndex = 0
    private var thinkingTimer: Handler? = null
    private var thinkingRunnable: Runnable? = null

    private val availableModels = listOf(
        ModelItem("deepseek-v3", "DeepSeek V3", true),
        ModelItem("kimi-2.5", "Kimi 2.5", false),
        ModelItem("glm-5", "GLM-5", false),
        ModelItem("minimax-m2.5", "MiniMax M2.5", false),
        ModelItem("doubao-2.0", "豆包 2.0", false)
    )

    data class ModelItem(val id: String, val name: String, val available: Boolean)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityChatBinding.inflate(layoutInflater)
        setContentView(binding.root)
        ThemeHelper.applyToActivity(this)

        apiService = ApiService(this)
        prefs = PreferencesManager.getInstance(this)
        chatDb = ChatDatabase(this)
        currentModel = prefs.getCurrentModel()
        markwon = Markwon.builder(this)
            .usePlugin(HtmlPlugin.create())
            .usePlugin(LinkifyPlugin.create())
            
            .build()

        // 恢复上次sessionId
        val savedSessionId = prefs.getSessionId()
        if (!savedSessionId.isNullOrEmpty()) {
            sessionId = savedSessionId
        }

        // 确保状态干净：每次打开重置
        isGenerating = false
        messageQueue.clear()
        setupUI()
        handleIntent()
    }

    private fun setupUI() {
        binding.btnMenu.setOnClickListener { toggleSidebar() }
        binding.btnNew.setOnClickListener { createNewChat() }
        binding.btnHome.setOnClickListener { goHome() }

        adapter = MessageAdapter(messages, markwon)
        binding.rvMessages.layoutManager = LinearLayoutManager(this).apply { stackFromEnd = true }
        binding.rvMessages.adapter = adapter

        binding.etInput.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_SEND) { sendMessage(); true } else false
        }
        binding.etInput.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                binding.btnSend.isEnabled = !s.isNullOrBlank() || pendingAttachments.isNotEmpty()
            }
        })

        binding.btnAttach.setOnClickListener { openFilePicker() }
        binding.optionCamera.setOnClickListener { attachPanelVisible = false; binding.attachPanel.visibility = View.GONE; openCamera() }
        binding.optionAlbum.setOnClickListener { attachPanelVisible = false; binding.attachPanel.visibility = View.GONE; openAlbum() }
        binding.optionFile.setOnClickListener { attachPanelVisible = false; binding.attachPanel.visibility = View.GONE; openDocPicker() }
        binding.optionVideo.setOnClickListener { attachPanelVisible = false; binding.attachPanel.visibility = View.GONE; openVideoPicker() }
        binding.btnSend.setOnClickListener { sendMessage() }
        binding.btnStop.setOnClickListener { stopGenerate() }

        binding.quickTask.setOnClickListener { quickAction("帮我创建一个任务") }
        binding.quickWebsite.setOnClickListener { quickAction("帮我搭建一个网页") }
        binding.quickResearch.setOnClickListener { quickAction("帮我做一份市场调研") }

        binding.btnModelSelect.setOnClickListener { showModelSelector() }
        updateEmptyState()
    }

    // v1.94b: 从后台回到前台时自动刷新聊天记录
    override fun onResume() {
        super.onResume()
        // v1.99: 恢复状态栏显示
        if (isGenerating) {
            binding.statusBar.visibility = View.VISIBLE
            binding.tvStatus.text = "AI正在回复中..."
            // v4.9.4: 正在生成时不重新加载历史，SSE回调还在更新
        } else {
            binding.statusBar.visibility = View.GONE
            if (!sessionId.isNullOrEmpty()) {
                loadChatHistoryFromBridge()
            }
        }
    }

    private fun handleIntent() {
        if (intent.getBooleanExtra("new", false)) {
            sessionId = null
            messages.clear()
            adapter.notifyDataSetChanged()
            updateEmptyState()
        }
        val querySessionId = intent.getStringExtra("session_id")
        if (!querySessionId.isNullOrEmpty()) {
            sessionId = querySessionId
            loadChatHistoryFromBridge()
        } else if (!sessionId.isNullOrEmpty()) {
            loadChatHistoryFromBridge()
        }
        val autoMsg = intent.getStringExtra("msg")
        val shouldSend = intent.getBooleanExtra("send", false)
        if (!autoMsg.isNullOrEmpty()) {
            binding.etInput.setText(autoMsg)
            if (shouldSend) binding.etInput.postDelayed({ sendMessage() }, 300)
        }
        val storedAutoMsg = prefs.getAutoSendMsg()
        if (!storedAutoMsg.isNullOrEmpty()) {
            prefs.clearAutoSendMsg()
            binding.etInput.setText(storedAutoMsg)
            binding.etInput.postDelayed({ sendMessage() }, 500)
        }

        // V2.0.42: 从服务器验证VIP+检查容器
        checkVipFromServer()
    }

    private fun toggleSidebar() {
        val sidebar = SidebarDrawer(this, sessionId) { conversation ->
            sessionId = conversation.session_id
            prefs.saveSessionId(conversation.session_id)
            messages.clear()
            adapter.notifyDataSetChanged()
            updateEmptyState()
            loadChatHistoryFromBridge()
        }
        sidebar.show()
    }

    private fun createNewChat() {
        lifecycleScope.launch {
            try {
                val result = apiService.createConversation()
                val newSessionId = result?.data?.session_id
                if (!newSessionId.isNullOrEmpty()) {
                    sessionId = newSessionId
                    prefs.saveSessionId(newSessionId)
                }
            } catch (_: Exception) { }
            messages.clear()
            adapter.notifyDataSetChanged()
            updateEmptyState()
        }
    }

    private fun goHome() {
        startActivity(Intent(this, MainActivity::class.java).apply { flags = Intent.FLAG_ACTIVITY_CLEAR_TOP })
        finish()
    }

    private fun quickAction(text: String) {
        binding.etInput.setText(text)
        sendMessage()
    }

    private fun sendMessage() {
        val text = binding.etInput.text.toString().trim()
        if (text.isEmpty() && pendingAttachments.isEmpty()) return
        if (isGenerating && currentCall == null) {
            isGenerating = false
            stopThinkingAnimation()
            cancelSseTimeout()
        }
        if (isGenerating) return
        binding.etInput.text?.clear()

        val hasAttachments = pendingAttachments.isNotEmpty()
        val attachments = mutableListOf<PendingAttachment>()
        if (hasAttachments) {
            attachments.addAll(pendingAttachments)
            pendingAttachments.clear()
            binding.attachmentPreview.visibility = View.GONE
        }

        val imageAttachments = attachments.filter { it.isImage }
        val videoAttachments = attachments.filter { it.isVideo }
        val fileAttachments = attachments.filter { !it.isImage && !it.isVideo }

        if (hasAttachments) {
            lifecycleScope.launch {
                try {
                    // 图片先用本地URI显示，不依赖网络
                    val imageLocalUris = mutableListOf<String>()
                    for (imgAtt in imageAttachments) {
                        imageLocalUris.add(imgAtt.uri.toString())
                    }

                    // 图片单独一个气泡显示（用本地URI，立即可见）
                    if (imageLocalUris.isNotEmpty()) {
                        val localUri = imageLocalUris.first()
                        val displayText = if (text.isNotEmpty()) text else "图片"
                        messages.add(Message(role = "user", content = displayText, text = displayText, imageUrl = localUri))
                        sessionId?.let { chatDb.saveMessage(it, "user", if (text.isNotEmpty()) "[图片] $text" else "[图片]") }
                        adapter.notifyItemInserted(messages.size - 1)
                        scrollToBottom()
                    }

                    // v5.3: 使用已上传的URL（选附件时已自动上传）
                    // 等待还在上传中的附件完成（最多等30秒）
                    var waitCount = 0
                    while (attachments.any { it.uploadState == UploadState.UPLOADING } && waitCount < 60) {
                        delay(500)
                        waitCount++
                    }

                    // 图片：用已上传的URL
                    val uploadedImageUrls = mutableListOf<String>()
                    for (imgAtt in imageAttachments) {
                        if (imgAtt.uploadedUrl != null) {
                            uploadedImageUrls.add(imgAtt.uploadedUrl!!)
                        } else if (imgAtt.uploadState == UploadState.FAILED) {
                            val url = doUploadFile(imgAtt.cachedFile, imgAtt.mimeType)
                            if (url != null) uploadedImageUrls.add(url)
                        }
                        imgAtt.cachedFile.delete()
                    }
                    if (uploadedImageUrls.isNotEmpty()) {
                        // v1.97: 合并图片+文字为一条消息，不再拆成两条
                        val userText = if (text.isNotEmpty()) text else "请看这张图片"
                        messageQueue.add("__IMGTEXT__::__" + uploadedImageUrls.first() + "|||" + userText)
                    } else if (imageLocalUris.isNotEmpty()) {
                        val userText = if (text.isNotEmpty()) text else "请看这张图片"
                        messageQueue.add("__IMGTEXT__::__|||" + userText)
                    }

                    // 文件
                    var messageText = text
                    val fileParts = mutableListOf<String>()
                    val fileCardsList = mutableListOf<com.chuangpu.ai.model.FileCard>()
                    for (fileAtt in fileAttachments) {
                        val fileUrl = if (fileAtt.uploadedUrl != null) fileAtt.uploadedUrl!! else doUploadFile(fileAtt.cachedFile, fileAtt.mimeType)
                        if (fileUrl != null) {
                            fileParts.add("[文件:${fileAtt.fileName}]($fileUrl)")
                            val ext = fileAtt.fileName.substringAfterLast(".", "").lowercase()
                            val icon = when(ext) { "pdf" -> "📕"; "doc","docx" -> "📘"; "xls","xlsx" -> "📗"; "ppt","pptx" -> "📊"; "zip","rar","7z" -> "📦"; "txt" -> "📝"; "mp3","wav" -> "🎵"; else -> "📄" }
                            val typeName = when(ext) { "pdf" -> "PDF"; "doc","docx" -> "Word"; "xls","xlsx" -> "Excel"; "ppt","pptx" -> "PPT"; "zip","rar","7z" -> "压缩包"; "txt" -> "文本"; "mp3","wav" -> "音频"; else -> "文件" }
                            val fullFileUrl = if (fileUrl.startsWith("/")) "https://ai.xianbaba188.cn$fileUrl" else fileUrl
                            fileCardsList.add(com.chuangpu.ai.model.FileCard(url = fullFileUrl, filename = fileAtt.fileName, type = typeName, size = "", icon = icon))
                        }
                        fileAtt.cachedFile.delete()
                    }

                    // v2.0.19: 保存本地URI用于缩略图
                    var savedLocalVideoUri: String? = null
                    if (videoAttachments.isNotEmpty()) {
                        savedLocalVideoUri = videoAttachments.first().uri.toString()
                    }
                    val uploadedVideoUrls = mutableListOf<String>()
                    for (vidAtt in videoAttachments) {
                        if (vidAtt.uploadedUrl != null) {
                            uploadedVideoUrls.add(vidAtt.uploadedUrl!!)
                        } else if (vidAtt.uploadState == UploadState.FAILED) {
                            val url = doUploadVideo(vidAtt.cachedFile, vidAtt.mimeType)
                            if (url != null) uploadedVideoUrls.add(url)
                        }
                        // v2.0.72: 上传成功后把视频复制到video_cache，播放时秒开
                        val videoCacheDir = File(cacheDir, "video_cache")
                        if (!videoCacheDir.exists()) videoCacheDir.mkdirs()
                        val vidUrl = if (vidAtt.uploadedUrl != null) vidAtt.uploadedUrl!! else ""
                        val vidFullUrl = if (vidUrl.startsWith("/")) "https://ai.xianbaba188.cn" + vidUrl else vidUrl
                        val cacheFileName = vidFullUrl.substringAfterLast("/").split("?")[0]
                        val destFile = File(videoCacheDir, cacheFileName)
                        if (!destFile.exists()) {
                            // 从content:// URI复制到缓存目录
                            try {
                                val srcUri = vidAtt.uri
                                if (srcUri != null && (srcUri.toString().startsWith("content://") || srcUri.toString().startsWith("file://"))) {
                                    val input = contentResolver.openInputStream(srcUri)
                                    if (input != null) {
                                        val output = java.io.FileOutputStream(destFile)
                                        val buf = ByteArray(8192)
                                        var n: Int
                                        while (input.read(buf).also { n = it } != -1) {
                                            output.write(buf, 0, n)
                                        }
                                        output.flush()
                                        output.close()
                                        input.close()
                                        android.util.Log.d("ChatActivity", "Video cached: ${destFile.absolutePath}")
                                    }
                                } else if (vidAtt.cachedFile.exists()) {
                                    vidAtt.cachedFile.renameTo(destFile)
                                }
                            } catch (e: Exception) {
                                android.util.Log.e("ChatActivity", "Video cache failed", e)
                            }
                        }
                        vidAtt.cachedFile.delete()
                    }
                    // v2.0.18: 视频只发一条消息
                    if (uploadedVideoUrls.isNotEmpty()) {
                        val userText = if (text.isNotEmpty()) text else "请看这个视频"
                        val displayText = if (text.isNotEmpty()) text else "视频"
                        val videoFullUrl = if (uploadedVideoUrls.first().startsWith("/")) "https://ai.xianbaba188.cn" + uploadedVideoUrls.first() else uploadedVideoUrls.first()
                        messages.add(Message(role = "user", content = displayText, text = displayText, videoUrl = videoFullUrl, localVideoUri = savedLocalVideoUri))
                        sessionId?.let { chatDb.saveMessage(it, "user", "[视频] $displayText") }
                        adapter.notifyItemInserted(messages.size - 1)
                        scrollToBottom()
                        messageQueue.add("__VIDTEXT__::__" + uploadedVideoUrls.joinToString("||") + "|||" + userText)
                    } else if (videoAttachments.isNotEmpty()) {
                        runOnUiThread { android.widget.Toast.makeText(this@ChatActivity, "视频上传失败，请重新发送", android.widget.Toast.LENGTH_LONG).show() }
                    }
                    if (fileParts.isNotEmpty()) {
                        val filePart = fileParts.joinToString("\n")
                        messageText = if (messageText.isNotEmpty()) "$messageText\n$filePart" else filePart
                    }
                    // v1.97: 图片+文字已合并为一条消息，不再单独发文字
                    // 只有纯文件(无图片无视频)时才单独发文字气泡
                    val fileOnlyText = fileParts.joinToString("\n")
                    if (fileOnlyText.isNotEmpty() && uploadedImageUrls.isEmpty() && uploadedVideoUrls.isEmpty()) {
                        val fullText = if (text.isNotEmpty()) "$text\n$fileOnlyText" else fileOnlyText
                        messages.add(Message(role = "user", content = fullText, text = if (text.isNotEmpty()) text else "", fileCards = if (fileCardsList.isNotEmpty()) fileCardsList else null))
                        sessionId?.let { chatDb.saveMessage(it, "user", fullText) }
                        adapter.notifyItemInserted(messages.size - 1)
                        messageQueue.add(fullText)
                    }

                    scrollToBottom()
                    updateEmptyState()
                    processQueue()
                } catch (e: Exception) {
                    for (att in attachments) { att.cachedFile.delete() }
                    messageQueue.add(if (text.isNotEmpty()) text else " ")
                    processQueue()
                }
            }
        } else {
            // 纯文字消息
            messages.add(Message(role = "user", content = text, text = text))
            sessionId?.let { chatDb.saveMessage(it, "user", text) }
            adapter.notifyItemInserted(messages.size - 1)
            scrollToBottom()
            updateEmptyState()
            messageQueue.add(text)
            processQueue()
        }
    }

    private fun processQueue() {
        if (messageQueue.isEmpty()) {
            isGenerating = false
            stopThinkingAnimation()
            currentCall = null
            cancelSseTimeout()
            return
        }
        val text = messageQueue.removeAt(0)
        isGenerating = true
        startThinkingAnimation()

        if (sessionId.isNullOrEmpty()) {
            lifecycleScope.launch {
                try {
                    android.widget.Toast.makeText(this@ChatActivity, "正在创建会话...", android.widget.Toast.LENGTH_SHORT).show()
                    val result = apiService.createConversation()
                    android.util.Log.d("ChatActivity", "createConversation result=$result")
                    val newSessionId = result?.data?.session_id
                    android.util.Log.d("ChatActivity", "newSessionId=$newSessionId result.data=${result?.data}")
                    if (!newSessionId.isNullOrEmpty()) {
                        sessionId = newSessionId
                        prefs.saveSessionId(newSessionId)
                        android.widget.Toast.makeText(this@ChatActivity, "会话创建成功: ${newSessionId.take(8)}...", android.widget.Toast.LENGTH_SHORT).show()
                    } else {
                        android.widget.Toast.makeText(this@ChatActivity, "创建会话失败: result=$result data=${result?.data} sid=$newSessionId", android.widget.Toast.LENGTH_LONG).show()
                    }
                } catch (e: Exception) {
                    android.widget.Toast.makeText(this@ChatActivity, "创建会话异常: ${e.message}", android.widget.Toast.LENGTH_LONG).show()
                    android.util.Log.e("ChatActivity", "createConversation error", e)
                }
                if (sessionId.isNullOrEmpty()) {
                    val lastMsg = messages.lastOrNull()
                    if (lastMsg != null && lastMsg.role == "assistant" && lastMsg.content.isEmpty()) {
                        lastMsg.content = "网络异常，请重试"
                        adapter.notifyItemChanged(messages.size - 1)
                    }
                    finishGenerate()
                    return@launch
                }
                android.widget.Toast.makeText(this@ChatActivity, "发送消息中...", android.widget.Toast.LENGTH_SHORT).show()
                doSendSse(text)
            }
        } else {
            doSendSse(text)
        }
    }

    private fun doSendSse(text: String) {
        val sid = sessionId ?: run { finishGenerate(); processQueue(); return }
        // v1.94: 状态显示在气泡内
        var lastStatusText = ""  // 记录最后一次status文字
        var firstContentReceived = false  // 是否已收到第一条正式content
        
        messages.add(Message(role = "assistant", content = ""))
        adapter.notifyItemInserted(messages.size - 1)
        scrollToBottom()

        // 超时保底：120秒后如果SSE还没结束，强制结束
        startSseTimeout()

        // v1.97: 识别图片+文字合并消息、视频消息
        var msgText = text
        var images = emptyList<String>()
        var videos = emptyList<String>()
        if (text.startsWith("__IMGTEXT__::__")) {
            // v1.97: 合并格式 __IMGTEXT__::url|||用户文字
            val payload = text.substringAfter("__IMGTEXT__::__")
            val parts = payload.split("|||", limit = 2)
            val imgUrl = parts.getOrNull(0) ?: ""
            val userText = parts.getOrNull(1) ?: "请看这张图片"
            if (imgUrl.isNotEmpty()) {
                images = listOf(imgUrl)
            }
            msgText = userText  // 保留用户原始文字
        } else if (text.startsWith("__VIDTEXT__::__")) {
            // v1.100: 合并格式 __VIDTEXT__::url1||url2|||用户文字
            val payload = text.substringAfter("__VIDTEXT__::__")
            val parts = payload.split("|||", limit = 2)
            val vidUrls = parts.getOrNull(0)?.split("||")?.filter { it.isNotEmpty() } ?: emptyList()
            val userText = parts.getOrNull(1) ?: "请看这个视频"
            videos = vidUrls
            msgText = userText
        }

        currentCall = apiService.sendMessageSse(
            sessionId = sid,
            message = msgText,
            model = currentModel,
            images = images,
            videos = videos,
            onChunk = { type: String, chunk: String, thumbnail: String ->
                // 每收到chunk就重置超时
                resetSseTimeout()
                runOnUiThread {
                    val lastMsg = messages.lastOrNull()
                    if (lastMsg != null && lastMsg.role == "assistant") {
                        if (type == "replace_all") {
                            // Bridge检测到新文件时发送完整内容，替换而非追加
                            lastMsg.content = chunk
                            firstContentReceived = true
                        } else if (type == "image") {
                            // v4.9.4: Bridge发送独立图片事件，直接设置imageUrl
                            val imgUrl = chunk
                            if (imgUrl.isNotEmpty()) {
                                var fullUrl = imgUrl
                                if (fullUrl.startsWith("/")) {
                                    fullUrl = "https://ai.xianbaba188.cn" + fullUrl
                                }
                                lastMsg.imageUrl = fullUrl
                                firstContentReceived = true
                            }
                        } else if (type == "video") {
                            // v2.0.14: Bridge发送视频事件，含thumbnail
                            val vidUrl = chunk
                            if (vidUrl.isNotEmpty()) {
                                var fullUrl = vidUrl
                                if (fullUrl.startsWith("/")) {
                                    fullUrl = "https://ai.xianbaba188.cn" + fullUrl
                                }
                                lastMsg.videoUrl = fullUrl
                                // 缩略图URL
                                if (thumbnail.isNotEmpty()) {
                                    var thumbFull = thumbnail
                                    if (thumbFull.startsWith("/")) {
                                        thumbFull = "https://ai.xianbaba188.cn" + thumbFull
                                    }
                                    lastMsg.thumbnailUrl = thumbFull
                                }
                                firstContentReceived = true
                                val idx = messages.size - 1
                                adapter.notifyItemChanged(idx)
                                // 后台预下载视频到本地缓存
                                lifecycleScope.launch(Dispatchers.IO) {
                                    try {
                                        val cacheDir = File(cacheDir, "video_cache")
                                        if (!cacheDir.exists()) cacheDir.mkdirs()
                                        val fileName = fullUrl.hashCode().toString() + ".mp4"
                                        val cacheFile = File(cacheDir, fileName)
                                        if (!cacheFile.exists()) {
                                            // OSS539f59cbURL8f6c4ee37406URL
                                            val downloadUrl = if (fullUrl.contains(".oss-") && !fullUrl.contains("Signature")) "https://ai.xianbaba188.cn/agent/api/oss-media/" + fullUrl.split(".com/").lastOrNull() else fullUrl
                                            val url = java.net.URL(downloadUrl)
                                            val conn = url.openConnection()
                                            conn.connect()
                                            val input = conn.getInputStream()
                                            val output = java.io.FileOutputStream(cacheFile)
                                            val buf = ByteArray(8192)
                                            var n: Int
                                            while (input.read(buf).also { n = it } != -1) {
                                                output.write(buf, 0, n)
                                            }
                                            output.flush()
                                            output.close()
                                            input.close()
                                        }
                                    } catch (e: Exception) { android.util.Log.e("ChatActivity", "Video preload failed", e) }
                                }
                            }
                        } else if (type == "status") {
                            // v1.99: 状态同时更新顶部状态栏和气泡
                            lastStatusText = chunk
                            binding.tvStatus.text = chunk
                            if (!firstContentReceived) {
                                // 还没收到正式内容，气泡里也显示状态
                                lastMsg.content = "⏳ " + chunk
                            }
                        } else {
                            // v1.94: 第一次收到正式content时，清除状态文字
                            if (!firstContentReceived) {
                                firstContentReceived = true
                                lastMsg.content = chunk  // 替换掉状态文字
                            } else {
                                lastMsg.content += chunk  // 后续追加
                            }
                        }
                        adapter.notifyItemChanged(messages.size - 1)
                        scrollToBottom()
                    }
                }
            },
            onComplete = {
                runOnUiThread {
                    cancelSseTimeout()
                    val lastMsg = messages.lastOrNull()
                    if (lastMsg != null && lastMsg.role == "assistant") {
                        if (lastMsg.content.isEmpty()) {
                            messages.removeAt(messages.size - 1)
                            adapter.notifyItemRemoved(messages.size)
                        } else {
                            sessionId?.let { s -> chatDb.saveMessage(s, "assistant", lastMsg.content) }
                        }
                    }
                    finishGenerate()
                    processQueue()
                }
            },
            onError = { err: String ->
                runOnUiThread {
                    cancelSseTimeout()
                    val lastMsg = messages.lastOrNull()
                    if (lastMsg != null && lastMsg.role == "assistant" && lastMsg.content.isEmpty()) {
                        lastMsg.content = err
                        adapter.notifyItemChanged(messages.size - 1)
                    }
                    finishGenerate()
                    processQueue()
                }
            }
        )
    }

    private fun startSseTimeout() {
        cancelSseTimeout()
        sseTimeoutHandler = Handler(Looper.getMainLooper())
        sseTimeoutRunnable = Runnable {
            // 超时强制结束
            currentCall?.cancel()
            currentCall = null
            val lastMsg = messages.lastOrNull()
            if (lastMsg != null && lastMsg.role == "assistant" && lastMsg.content.isEmpty()) {
                lastMsg.content = "响应超时，请重试"
                adapter.notifyItemChanged(messages.size - 1)
            }
            finishGenerate()
            processQueue()
        }
        sseTimeoutHandler?.postDelayed(sseTimeoutRunnable!!, 120000)
    }

    private fun resetSseTimeout() {
        sseTimeoutHandler?.removeCallbacks(sseTimeoutRunnable!!)
        sseTimeoutHandler?.postDelayed(sseTimeoutRunnable!!, 120000)
    }

    private fun cancelSseTimeout() {
        sseTimeoutRunnable?.let { sseTimeoutHandler?.removeCallbacks(it) }
        sseTimeoutRunnable = null
        sseTimeoutHandler = null
    }

    private fun stopGenerate() {
        currentCall?.cancel()
        currentCall = null
        isGenerating = false
        messageQueue.clear()
        finishGenerate()
    }

    private fun finishGenerate() {
        isGenerating = false
        // v1.99: 生成结束，隐藏状态栏
        binding.statusBar.visibility = View.GONE
        binding.btnStop.visibility = View.GONE
        binding.btnSend.visibility = View.VISIBLE
    }

    private fun startThinkingAnimation() {
        // v1.99: 恢复顶部状态栏显示
        binding.btnStop.visibility = View.VISIBLE
        binding.btnSend.visibility = View.GONE
        binding.statusBar.visibility = View.VISIBLE
        binding.tvStatus.text = thinkingTexts[0]
        thinkingIndex = 0
        thinkingTimer = Handler(Looper.getMainLooper())
        thinkingRunnable = object : Runnable {
            override fun run() {
                if (isGenerating) {
                    thinkingIndex = (thinkingIndex + 1) % thinkingTexts.size
                    binding.tvStatus.text = thinkingTexts[thinkingIndex]
                    thinkingTimer?.postDelayed(this, 3000)
                }
            }
        }
        thinkingTimer?.postDelayed(thinkingRunnable!!, 3000)
    }

    private fun stopThinkingAnimation() {
        thinkingRunnable?.let { thinkingTimer?.removeCallbacks(it) }
        thinkingRunnable = null
        thinkingTimer = null
    }

    private var historyPollingJob: kotlinx.coroutines.Job? = null

    private fun loadChatHistoryFromBridge() {
        val sid = sessionId ?: return
        // v4.9.4: Cancel any existing polling
        historyPollingJob?.cancel()
        lifecycleScope.launch {
            try {
                val historyResult = apiService.getChatHistoryRaw(sid)
                val historyMsgs = historyResult?.get("messages") as? List<Map<String, Any?>> ?: emptyList()
                val isStillGenerating = historyResult?.get("is_generating") as? Boolean ?: false
                if (historyMsgs.isNotEmpty()) {
                    messages.clear()
                    for (m in historyMsgs) {
                        val content = m["content"] as? String ?: ""
                        // v1.100: 从content中解析图片/视频URL
                        var imageUrl: String? = null
                        var videoUrl: String? = null
                        var displayContent = content
                        if (m["role"] == "user") {
                            // 匹配 ![](url) 格式提取图片URL（支持https和相对路径）
                            val imgPattern = Regex("""!\[\]\(([^\)]+)\)""")
                            val imgMatch = imgPattern.find(content)
                            if (imgMatch != null) {
                                var imgPath = imgMatch.groupValues[1]
                                if (imgPath.startsWith("/")) {
                                    imgPath = "https://ai.xianbaba188.cn" + imgPath
                                }
                                imageUrl = imgPath
                                displayContent = displayContent.replace(imgMatch.value, "").trim()
                            }
                            // 匹配 [视频](url) 格式提取视频URL
                            val vidPattern = Regex("""\[视频\]\(([^\)]+)\)""")
                            val vidMatch = vidPattern.find(content)
                            if (vidMatch != null) {
                                var vidPath = vidMatch.groupValues[1]
                                if (vidPath.startsWith("/")) {
                                    vidPath = "https://ai.xianbaba188.cn" + vidPath
                                }
                                videoUrl = vidPath
                                displayContent = displayContent.replace(vidMatch.value, "").trim()
                            }
                            // 清理残留标记
                            displayContent = displayContent.replace("[图片]", "").replace("[视频]", "").trim()
                            if (displayContent.isEmpty() && imageUrl != null) displayContent = "图片"
                            if (displayContent.isEmpty() && videoUrl != null) displayContent = "视频"
                        } else if (m["role"] == "assistant") {
                            // v2.0.10: assistant消息也提取视频URL
                            val vidPattern = Regex("""\[视频\]\(([^\)]+)\)""")
                            val vidMatch = vidPattern.find(content)
                            if (vidMatch != null) {
                                var vidPath = vidMatch.groupValues[1]
                                if (vidPath.startsWith("/")) {
                                    vidPath = "https://ai.xianbaba188.cn" + vidPath
                                }
                                videoUrl = vidPath
                                displayContent = displayContent.replace(vidMatch.value, "").trim()
                            }
                            // 也提取图片
                            val imgPattern = Regex("""!\[\]\(([^\)]+)\)""")
                            for (imgMatch in imgPattern.findAll(content)) {
                                var imgPath = imgMatch.groupValues[1]
                                if (imgPath.startsWith("/")) {
                                    imgPath = "https://ai.xianbaba188.cn" + imgPath
                                }
                                if (imageUrl == null) imageUrl = imgPath
                            }
                            displayContent = displayContent.replace(imgPattern, "").trim()
                        }
                        // v2.0.24: 从历史消息中提取文件卡片
                        var histFileCards: List<com.chuangpu.ai.model.FileCard>? = null
                        if (m["role"] == "user") {
                            val flPat = Regex("""\[文件:([^\]]+)\]\(([^)]+)\)""")
                            val flMatches = flPat.findAll(content).toList()
                            if (flMatches.isNotEmpty()) {
                                histFileCards = flMatches.map { fl ->
                                    val fname = fl.groupValues[1]
                                    var furl = fl.groupValues[2]
                                    if (furl.startsWith("/")) furl = "https://ai.xianbaba188.cn" + furl
                                    val ext = fname.substringAfterLast(".", "").lowercase()
                                    val icon = when(ext) { "pdf" -> "📕"; "doc","docx" -> "📘"; "xls","xlsx" -> "📗"; "ppt","pptx" -> "📊"; "zip","rar","7z" -> "📦"; "txt" -> "📝"; "mp3","wav" -> "🎵"; else -> "📄" }
                                    val typeName = when(ext) { "pdf" -> "PDF"; "doc","docx" -> "Word"; "xls","xlsx" -> "Excel"; "ppt","pptx" -> "PPT"; "zip","rar","7z" -> "压缩包"; "txt" -> "文本"; "mp3","wav" -> "音频"; else -> "文件" }
                                    com.chuangpu.ai.model.FileCard(url = furl, filename = fname, type = typeName, size = "", icon = icon)
                                }
                                displayContent = displayContent.replace(flPat, "").trim()
                            }
                        }
                        messages.add(Message(role = m["role"] as? String ?: "user", content = displayContent, text = if (histFileCards != null && displayContent.isEmpty()) "" else displayContent, imageUrl = imageUrl, videoUrl = videoUrl, fileCards = histFileCards))
                    }
                    adapter.notifyDataSetChanged()
                    updateEmptyState()
                    scrollToBottom()
                }
                // v4.9.4: If session is still generating, poll for updates
                if (isStillGenerating) {
                    startHistoryPolling(sid)
                }
            } catch (e: Exception) {
            }
        }
    }

    // v4.9.4: Poll history while session is generating
    private fun startHistoryPolling(sid: String) {
        historyPollingJob?.cancel()
        historyPollingJob = lifecycleScope.launch {
            var pollCount = 0
            while (pollCount < 60) {  // max 3 minutes (60 * 3s)
                delay(3000)
                try {
                    val result = apiService.getChatHistoryRaw(sid)
                    val isGen = result?.get("is_generating") as? Boolean ?: false
                    val msgs = result?.get("messages") as? List<Map<String, Any?>> ?: emptyList()
                    if (msgs.isNotEmpty()) {
                        // Update messages in-place
                        messages.clear()
                        for (m in msgs) {
                            val content = m["content"] as? String ?: ""
                            var imageUrl: String? = null
                            var videoUrl: String? = null
                            var displayContent = content
                            if (m["role"] == "user") {
                                val imgPattern = Regex("""!\[\]\(([^\)]+)\)""")
                                val imgMatch = imgPattern.find(content)
                                if (imgMatch != null) {
                                    var imgPath = imgMatch.groupValues[1]
                                    if (imgPath.startsWith("/")) {
                                        imgPath = "https://ai.xianbaba188.cn" + imgPath
                                    }
                                    imageUrl = imgPath
                                    displayContent = displayContent.replace(imgMatch.value, "").trim()
                                }
                                val vidPattern = Regex("""\[视频\]\(([^\)]+)\)""")
                                val vidMatch = vidPattern.find(content)
                                if (vidMatch != null) {
                                    var vidPath = vidMatch.groupValues[1]
                                    if (vidPath.startsWith("/")) {
                                        vidPath = "https://ai.xianbaba188.cn" + vidPath
                                    }
                                    videoUrl = vidPath
                                    displayContent = displayContent.replace(vidMatch.value, "").trim()
                                }
                                displayContent = displayContent.replace("[图片]", "").replace("[视频]", "").trim()
                                if (displayContent.isEmpty() && imageUrl != null) displayContent = "图片"
                                if (displayContent.isEmpty() && videoUrl != null) displayContent = "视频"
                            } else {
                                // v2.0.10: assistant also extract video and image
                                val vidPattern2 = Regex("""\[视频\]\(([^\)]+)\)""")
                                val vidMatch2 = vidPattern2.find(content)
                                if (vidMatch2 != null) {
                                    var vidPath = vidMatch2.groupValues[1]
                                    if (vidPath.startsWith("/")) vidPath = "https://ai.xianbaba188.cn" + vidPath
                                    videoUrl = vidPath
                                    displayContent = displayContent.replace(vidMatch2.value, "").trim()
                                }
                                val aiImgPattern = Regex("""!\[.*?\]\((https?://[^)]+\.(png|jpg|jpeg|gif|webp))\)""", RegexOption.IGNORE_CASE)
                                val aiImgMatch = aiImgPattern.find(displayContent)
                                if (aiImgMatch != null) {
                                    imageUrl = aiImgMatch.groupValues[1]
                                    displayContent = aiImgPattern.replace(displayContent, "").trim()
                                }
                            }
                            // v2.0.25: 从历史消息中提取文件卡片
                            var pollFileCards: List<com.chuangpu.ai.model.FileCard>? = null
                            if (m["role"] == "user") {
                                val pflPat = Regex("""\[文件:([^\]]+)\]\(([^)]+)\)""")
                                val pflMatches = pflPat.findAll(content).toList()
                                if (pflMatches.isNotEmpty()) {
                                    pollFileCards = pflMatches.map { pfl ->
                                        val fname = pfl.groupValues[1]
                                        var furl = pfl.groupValues[2]
                                        if (furl.startsWith("/")) furl = "https://ai.xianbaba188.cn" + furl
                                        val ext2 = fname.substringAfterLast(".", "").lowercase()
                                        val icon = when(ext2) { "pdf" -> "📕"; "doc","docx" -> "📘"; "xls","xlsx" -> "📗"; "ppt","pptx" -> "📊"; "zip","rar","7z" -> "📦"; "txt" -> "📝"; "mp3","wav" -> "🎵"; else -> "📄" }
                                        val typeName = when(ext2) { "pdf" -> "PDF"; "doc","docx" -> "Word"; "xls","xlsx" -> "Excel"; "ppt","pptx" -> "PPT"; "zip","rar","7z" -> "压缩包"; "txt" -> "文本"; "mp3","wav" -> "音频"; else -> "文件" }
                                        com.chuangpu.ai.model.FileCard(url = furl, filename = fname, type = typeName, size = "", icon = icon)
                                    }
                                    displayContent = displayContent.replace(pflPat, "").trim()
                                }
                            }
                            messages.add(Message(role = m["role"] as? String ?: "user", content = displayContent, text = if (pollFileCards != null && displayContent.isEmpty()) "" else displayContent, imageUrl = imageUrl, videoUrl = videoUrl, fileCards = pollFileCards))
                        }
                        adapter.notifyDataSetChanged()
                        scrollToBottom()
                    }
                    if (!isGen) {
                        break
                    }
                    pollCount++
                } catch (e: Exception) {
                    pollCount++
                }
            }
        }
    }

    private fun showModelSelector() {
        binding.etInput.clearFocus()
        val dialog = BottomSheetDialog(this)
        val view = LayoutInflater.from(this).inflate(R.layout.dialog_model_selector, null)
        dialog.setContentView(view)
        val modelList = view.findViewById<LinearLayout>(R.id.modelListContainer)
        modelList.removeAllViews()
        for (model in availableModels) {
            val itemView = LayoutInflater.from(this).inflate(R.layout.item_model, modelList, false)
            val tvName = itemView.findViewById<TextView>(R.id.tvModelName)
            val tvBadge = itemView.findViewById<TextView>(R.id.tvModelBadge)
            val tvCheck = itemView.findViewById<TextView>(R.id.tvModelCheck)
            tvName.text = model.name
            tvBadge.visibility = if (model.available) View.GONE else View.VISIBLE
            if (!model.available) tvBadge.text = "即将上线"
            if (model.id == currentModel) {
                itemView.setBackgroundResource(R.drawable.bg_model_active)
                tvCheck.visibility = View.VISIBLE
                tvCheck.text = "✓"
            } else {
                tvCheck.visibility = View.GONE
            }
            itemView.setOnClickListener {
                if (!model.available) {
                    return@setOnClickListener
                }
                currentModel = model.id
                prefs.setCurrentModel(model.id)
                dialog.dismiss()
            }
            modelList.addView(itemView)
        }
        view.findViewById<TextView>(R.id.tvCancel)?.setOnClickListener { dialog.dismiss() }
        dialog.show()
    }

    private fun scrollToBottom() {
        binding.rvMessages.post {
            if (adapter.itemCount > 0) binding.rvMessages.scrollToPosition(adapter.itemCount - 1)
        }
    }

    private fun updateEmptyState() {
        if (messages.isEmpty()) {
            binding.emptyState.visibility = View.VISIBLE
            binding.rvMessages.visibility = View.GONE
        } else {
            binding.emptyState.visibility = View.GONE
            binding.rvMessages.visibility = View.VISIBLE
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        connectHandler.removeCallbacksAndMessages(null)
        thinkingRunnable?.let { thinkingTimer?.removeCallbacks(it) }
        currentCall?.cancel()
    }

    override fun onBackPressed() = goHome()

    private var attachPanelVisible = false

    private fun openFilePicker() {
        attachPanelVisible = !attachPanelVisible
        binding.attachPanel.visibility = if (attachPanelVisible) View.VISIBLE else View.GONE
    }

    private fun openCamera() {
        val intent = Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE)
        if (intent.resolveActivity(packageManager) != null) {
            startActivityForResult(intent, REQUEST_CAMERA)
        }
    }

    private fun openAlbum() {
        val intent = Intent(Intent.ACTION_PICK, android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
            type = "image/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*"))
        }
        startActivityForResult(intent, REQUEST_ALBUM)
    }

    private fun openDocPicker() {
        startActivityForResult(Intent(this, FilePickerActivity::class.java), REQUEST_FILE)
    }

    private fun openVideoPicker() {
        val intent = Intent(Intent.ACTION_PICK, android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI).apply {
            type = "video/*"
        }
        startActivityForResult(intent, REQUEST_VIDEO)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode != RESULT_OK) return
        when (requestCode) {
            REQUEST_CAMERA -> {
                data?.data?.let { addPendingAttachment(it) }
                    ?: data?.extras?.get("data")?.let { bitmap ->
                        val tempFile = java.io.File(cacheDir, "camera_" + System.currentTimeMillis() + ".jpg")
                        java.io.FileOutputStream(tempFile).use { fos ->
                            (bitmap as android.graphics.Bitmap).compress(android.graphics.Bitmap.CompressFormat.JPEG, 90, fos)
                        }
                        addPendingAttachment(android.net.Uri.fromFile(tempFile))
                    }
            }
            REQUEST_ALBUM -> {
                data?.let { d ->
                    val clip = d.clipData
                    if (clip != null) {
                        for (i in 0 until clip.itemCount) {
                            addPendingAttachment(clip.getItemAt(i).uri)
                        }
                    } else {
                        d.data?.let { addPendingAttachment(it) }
                    }
                }
            }
            REQUEST_FILE -> {
                data?.getStringArrayExtra(FilePickerActivity.EXTRA_SELECTED_URIS)?.forEach {
                    addPendingAttachment(Uri.parse(it))
                }
            }
            REQUEST_VIDEO -> {
                data?.data?.let { addPendingAttachment(it) }
            }
        }
    }

    private fun addPendingAttachment(uri: Uri) {
        val mimeType = contentResolver.getType(uri) ?: "application/octet-stream"
        val fileName = getFileName(uri) ?: "file"
        val isImage = mimeType.startsWith("image/")
        val isVideo = mimeType.startsWith("video/")
        // 直接用URI，不拷缓存
        val att = PendingAttachment(
            java.io.File(cacheDir, "pending_${System.currentTimeMillis()}_$fileName"),
            fileName, mimeType, isImage, isVideo, uri
        )
        att.uploadState = UploadState.IDLE
        att.uploadProgress = 0
        pendingAttachments.add(att)
        updateAttachmentPreview()
        startAttachmentUpload(pendingAttachments.lastIndex)
    }

    private fun updateAttachmentPreview() {
        if (pendingAttachments.isEmpty()) {
            binding.attachmentPreview.visibility = View.GONE
            return
        }
        binding.attachmentPreview.visibility = View.VISIBLE
        binding.attachmentPreview.removeAllViews()
        val container = android.widget.HorizontalScrollView(this).apply { isFillViewport = true }
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(8, 8, 8, 8)
        }
        for ((index, att) in pendingAttachments.withIndex()) {
            val itemWrap = android.widget.FrameLayout(this).apply {
                layoutParams = LinearLayout.LayoutParams(120, 120).apply { marginEnd = 8 }
            }
            if (att.isImage) {
                val img = ImageView(this).apply {
                    layoutParams = android.widget.FrameLayout.LayoutParams(120, 120)
                    scaleType = ImageView.ScaleType.FIT_CENTER
                    setImageURI(att.uri)
                    setBackgroundColor(0xFF2A2A3A.toInt())
                }
                itemWrap.addView(img)
            } else if (att.isVideo) {
                // 视频缩略图：提取第一帧
                val thumb = android.widget.ImageView(this).apply {
                    layoutParams = android.widget.FrameLayout.LayoutParams(120, 120)
                    scaleType = ImageView.ScaleType.CENTER_CROP
                    setBackgroundColor(0xFF2A2A3A.toInt())
                }
                try {
                    val retriever = android.media.MediaMetadataRetriever()
                    retriever.setDataSource(this@ChatActivity, att.uri)
                    val bitmap = retriever.getFrameAtTime(0)
                    retriever.release()
                    if (bitmap != null) {
                        thumb.setImageBitmap(bitmap)
                    }
                } catch (e: Exception) { }
                // 叠加播放图标
                val playIcon = TextView(this).apply {
                    text = "▶"
                    textSize = 28f
                    setTextColor(0xB3FFFFFF.toInt())
                    gravity = android.view.Gravity.CENTER
                    layoutParams = android.widget.FrameLayout.LayoutParams(120, 120)
                }
                itemWrap.addView(thumb)
                itemWrap.addView(playIcon)
            } else {
                val tv = TextView(this).apply {
                    layoutParams = android.widget.FrameLayout.LayoutParams(120, 120)
                    text = att.fileName
                    setTextColor(resources.getColor(android.R.color.white, null))
                    textSize = 11f
                    maxLines = 3
                    setPadding(8, 8, 8, 8)
                    setBackgroundColor(0xFF2A2A3A.toInt())
                }
                itemWrap.addView(tv)
            }
            // 上传状态指示器
            val statusOverlay = android.widget.FrameLayout(this).apply {
                layoutParams = android.widget.FrameLayout.LayoutParams(120, 120)
            }
            when (att.uploadState) {
                UploadState.UPLOADING -> {
                    val progressView = android.widget.LinearLayout(this).apply {
                        orientation = android.widget.LinearLayout.VERTICAL
                        gravity = android.view.Gravity.CENTER
                        setBackgroundColor(0x99000000.toInt())
                        layoutParams = android.widget.FrameLayout.LayoutParams(120, 120)
                    }
                    val progressText = TextView(this).apply {
                        text = if (att.uploadProgress > 0) "${att.uploadProgress}%" else "上传中"
                        setTextColor(0xFFFFFFFF.toInt())
                        textSize = 12f
                        gravity = android.view.Gravity.CENTER
                    }
                    val spinner = android.widget.ProgressBar(this).apply {
                        isIndeterminate = att.uploadProgress == 0
                        if (!isIndeterminate) progress = att.uploadProgress
                        layoutParams = android.widget.LinearLayout.LayoutParams(48, 48)
                    }
                    progressView.addView(spinner)
                    progressView.addView(progressText)
                    statusOverlay.addView(progressView)
                }
                UploadState.SUCCESS -> {
                    val checkMark = TextView(this).apply {
                        text = "✓"
                        setTextColor(0xFF4CAF50.toInt())
                        textSize = 20f
                        setBackgroundColor(0x80000000.toInt())
                        gravity = android.view.Gravity.CENTER
                        layoutParams = android.widget.FrameLayout.LayoutParams(32, 32, android.view.Gravity.END or android.view.Gravity.BOTTOM)
                    }
                    statusOverlay.addView(checkMark)
                }
                UploadState.FAILED -> {
                    val failOverlay = android.widget.LinearLayout(this).apply {
                        orientation = android.widget.LinearLayout.VERTICAL
                        gravity = android.view.Gravity.CENTER
                        setBackgroundColor(0xCC000000.toInt())
                        layoutParams = android.widget.FrameLayout.LayoutParams(120, 120)
                    }
                    val failText = TextView(this).apply {
                        text = "✗ 失败"
                        setTextColor(0xFFFF5252.toInt())
                        textSize = 12f
                        gravity = android.view.Gravity.CENTER
                    }
                    val retryBtn = TextView(this).apply {
                        text = "重试"
                        setTextColor(0xFFFFFFFF.toInt())
                        textSize = 11f
                        setBackgroundColor(0xFF4CAF50.toInt())
                        setPadding(12, 4, 12, 4)
                        gravity = android.view.Gravity.CENTER
                        setOnClickListener {
                            startAttachmentUpload(index)
                        }
                    }
                    failOverlay.addView(failText)
                    failOverlay.addView(retryBtn)
                    statusOverlay.addView(failOverlay)
                }
                UploadState.IDLE -> {} // 不显示
            }
            itemWrap.addView(statusOverlay)
            // 删除按钮（上传中不显示）
            if (att.uploadState != UploadState.UPLOADING) {
                val removeBtn = TextView(this).apply {
                    text = "X"
                    setTextColor(0xFFFFFFFF.toInt())
                    textSize = 10f
                    setBackgroundColor(0x99000000.toInt())
                    setPadding(4, 2, 4, 2)
                    layoutParams = android.widget.FrameLayout.LayoutParams(
                        android.widget.FrameLayout.LayoutParams.WRAP_CONTENT,
                        android.widget.FrameLayout.LayoutParams.WRAP_CONTENT,
                        android.view.Gravity.END or android.view.Gravity.TOP
                    )
                    setOnClickListener {
                        pendingAttachments.removeAt(index)
                        updateAttachmentPreview()
                    }
                }
                itemWrap.addView(removeBtn)
            }
            row.addView(itemWrap)
        }
        container.addView(row)
        binding.attachmentPreview.addView(container)
    }

    private fun startAttachmentUpload(index: Int) {
        if (index < 0 || index >= pendingAttachments.size) return
        val att = pendingAttachments[index]
        if (att.uploadState == UploadState.UPLOADING || att.uploadState == UploadState.SUCCESS) return
        att.uploadState = UploadState.UPLOADING
        att.uploadProgress = 0
        updateAttachmentPreview()
        lifecycleScope.launch {
            val progressCallback: (Int) -> Unit = { progress ->
                att.uploadProgress = progress
                runOnUiThread { updateAttachmentPreview() }
            }
            val url = when {
                att.isVideo -> apiService.doUploadVideoFromUri(att.uri, att.mimeType, att.fileName, progressCallback)
                att.isImage -> apiService.uploadImageFromUri(att.uri, att.mimeType, att.fileName, progressCallback)
                else -> apiService.uploadFileFromUri(att.uri, att.mimeType, att.fileName, progressCallback)
            }
            if (url != null) {
                att.uploadState = UploadState.SUCCESS
                att.uploadProgress = 100
                att.uploadedUrl = url
            } else {
                att.uploadState = UploadState.FAILED
                att.uploadProgress = 0
            }
            updateAttachmentPreview()
        }
    }

    private suspend fun doUploadFile(cachedFile: java.io.File, mimeType: String, onProgress: (Int) -> Unit = {}): String? {
        if (!cachedFile.exists() || cachedFile.length() == 0L) return null
        if (cachedFile.length() > 30 * 1024 * 1024) return null
        onProgress(30)
        val result = apiService.uploadFile(cachedFile, mimeType)
        if (result != null) onProgress(90)
        return result
    }

    private suspend fun doUploadVideo(cachedFile: java.io.File, mimeType: String, onProgress: (Int) -> Unit = {}): String? {
        if (!cachedFile.exists() || cachedFile.length() == 0L) return null
        if (cachedFile.length() > 20 * 1024 * 1024) return null  // 视频20MB限制
        return apiService.doUploadVideo(cachedFile, mimeType, onProgress)
    }

    private fun getFileName(uri: Uri): String? {
        var name: String? = null
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0) name = cursor.getString(idx)
            }
        }
        return name ?: uri.lastPathSegment
    }
}

// v2.0.26: 文件卡片点击 - 下载到本地后用Chooser打开/分享
fun openFile(ctx: android.content.Context, url: String, fileName: String, ext: String) {
    Thread {
        try {
            val cacheDir2 = File(ctx.cacheDir, "file_cache")
            if (!cacheDir2.exists()) cacheDir2.mkdirs()
            val safeName = "file_" + java.util.UUID.randomUUID().toString().substring(0, 8) + "." + ext
            val localFile = File(cacheDir2, safeName)
            if (!localFile.exists()) {
                val fullUrl = if (url.startsWith("/")) "https://ai.xianbaba188.cn" + url else url
                val conn = java.net.URL(fullUrl).openConnection()
                conn.connectTimeout = 15000
                conn.readTimeout = 60000
                conn.connect()
                val input = conn.getInputStream()
                val output = java.io.FileOutputStream(localFile)
                val buf = ByteArray(8192)
                var n: Int
                while (input.read(buf).also { n = it } != -1) {
                    output.write(buf, 0, n)
                }
                output.flush(); output.close(); input.close()
            }
            val mimeType = android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext.lowercase())
                ?: "application/octet-stream"
            val fileUri = androidx.core.content.FileProvider.getUriForFile(ctx, ctx.packageName + ".fileprovider", localFile)
            // v2.0.26: 用ACTION_SEND分享，微信等社交APP兼容性更好
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, fileUri)
                putExtra(Intent.EXTRA_TEXT, fileName)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                // clipData确保URI权限正确转发给目标APP
                clipData = android.content.ClipData.newRawUri("", fileUri)
            }
            val chooser = Intent.createChooser(shareIntent, fileName).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            ctx.startActivity(chooser)
        } catch (e: Exception) {
            e.printStackTrace()
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                android.widget.Toast.makeText(ctx, "打开失败: " + e.message, android.widget.Toast.LENGTH_LONG).show()
                try {
                    val fullUrl = if (url.startsWith("/")) "https://ai.xianbaba188.cn" + url else url
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(fullUrl)).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                    ctx.startActivity(intent)
                } catch (e2: Exception) {
                    android.widget.Toast.makeText(ctx, "浏览器也无法打开", android.widget.Toast.LENGTH_SHORT).show()
                }
            }
        }
    }.start()
}

class MessageAdapter(
    private val messages: MutableList<Message>,
    private val markwon: Markwon
) : RecyclerView.Adapter<MessageAdapter.ViewHolder>() {

    // v4.9.4: Match both absolute and relative image URLs
    private val imagePattern = Regex("""!\[[^\]]*\]\(((?:https?://|/)[^)]+\.(png|jpg|jpeg|gif|webp))\)""", RegexOption.IGNORE_CASE)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val layout = if (viewType == 0) R.layout.item_message_user else R.layout.item_message_ai
        return ViewHolder(LayoutInflater.from(parent.context).inflate(layout, parent, false))
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val msg = messages[position]
        if (msg.role == "assistant") {
            var content = msg.content
            var imageUrl: String? = null

            if (content.isNotEmpty()) {
                content = content.replace("/root/.openclaw/workspace/", "https://ai.xianbaba188.cn/agent/api/workspace/")
                content = content.replace("sandbox://.openclaw/workspace/", "https://ai.xianbaba188.cn/agent/api/workspace/")
                content = content.replace("MEDIA:", "")
                content = content.replace(Regex("\n{3,}"), "\n\n")
                content = content.replace(Regex("""`([^`]+\.(png|jpg|jpeg|gif|webp|svg|bmp))`""", RegexOption.IGNORE_CASE)) { match ->
                    val path = match.groupValues[1]
                    when {
                        path.startsWith("http") -> "![$path]($path)"
                        path.startsWith("/") -> "![$path](https://ai.xianbaba188.cn$path)"
                        else -> "![$path](https://ai.xianbaba188.cn/agent/api/workspace/$path)"
                    }
                }
                content = content.replace("(/agent/api/workspace/", "(https://ai.xianbaba188.cn/agent/api/workspace/")
                // 兼容纯URL图片
                content = content.replace(Regex("""(?<!!\[)(https?://[^\s\)]+\.(png|jpg|jpeg|gif|webp))""", RegexOption.IGNORE_CASE)) { match ->
                    val url = match.groupValues[1]
                    "![image]($url)"
                }

                // v4.9.4: Extract ALL image URLs for multi-image support
                val allImgMatches = imagePattern.findAll(content).toList()
                if (allImgMatches.isNotEmpty()) {
                    imageUrl = allImgMatches[0].groupValues[1]  // first image
                    // Collect remaining images for multi-render
                    for (i in 1 until allImgMatches.size) {
                        // Additional images will be picked up by the adapter via allImages list
                    }
                }
                content = imagePattern.replace(content, "").trim()

                // v2.0.10: 如果有视频URL，去掉[视频](url)链接，避免重复显示
                if (!msg.videoUrl.isNullOrEmpty()) {
                    content = content.replace(Regex("""\[视频\]\([^)]+\)"""), "").trim()
                }
                // v2.0.24: 去掉[文件:xxx](url)链接，用文件卡片展示
                content = content.replace(Regex("""\[文件:[^\]]+\]\([^)]+\)"""), "").trim()
                if (content.isNotBlank()) {
                    markwon.setMarkdown(holder.tvContent, content)
                    holder.tvContent.visibility = View.VISIBLE
                } else {
                    holder.tvContent.visibility = View.GONE
                }
            } else {
                holder.tvContent.visibility = View.GONE
            }

            // v4.9.4: Multi-image support - extract ALL images from original content
            val allImages = mutableListOf<String>()
            if (imageUrl != null) allImages.add(imageUrl)
            // Also extract images directly from msg.content (original markdown with all images)
            val origContent = msg.content.replace("/root/.openclaw/workspace/", "https://ai.xianbaba188.cn/agent/api/workspace/")
                .replace("sandbox://.openclaw/workspace/", "https://ai.xianbaba188.cn/agent/api/workspace/")
                .replace("(/agent/api/workspace/", "(https://ai.xianbaba188.cn/agent/api/workspace/")
            for (m in imagePattern.findAll(origContent)) {
                var u = m.groupValues[1]
                if (u.startsWith("/")) u = "https://ai.xianbaba188.cn" + u
                if (u !in allImages) allImages.add(u)
            }
            // Also check msg.imageUrl (set by image event)
            if (!msg.imageUrl.isNullOrEmpty()) {
                var evtUrl = msg.imageUrl!!
                if (evtUrl.startsWith("/")) evtUrl = "https://ai.xianbaba188.cn" + evtUrl
                if (evtUrl !in allImages) allImages.add(evtUrl)
            }
            
            holder.llImages?.let { container ->
                container.removeAllViews()
                if (allImages.isNotEmpty()) {
                    container.visibility = View.VISIBLE
                    container.orientation = LinearLayout.VERTICAL
                    val dp = holder.itemView.context.resources.displayMetrics.density
                    val imgWidth = (220 * dp).toInt()  // 220dp wide thumbnail
                    for (imgUrl in allImages) {
                        val thumb = ImageView(holder.itemView.context).apply {
                            layoutParams = LinearLayout.LayoutParams(imgWidth, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                                topMargin = (4 * dp).toInt()
                            }
                            adjustViewBounds = true
                            maxHeight = (220 * dp).toInt()
                            scaleType = ImageView.ScaleType.FIT_CENTER
                            setBackgroundColor(0xFF1A1A2E.toInt())
                            setPadding(4, 4, 4, 4)
                        }
                        Glide.with(holder.itemView.context).load(imgUrl).into(thumb)
                        thumb.setOnClickListener {
                            val intent = Intent(it.context, FullscreenImageActivity::class.java)
                            intent.putExtra("image_url", imgUrl)
                            it.context.startActivity(intent)
                        }
                        container.addView(thumb)
                    }
                } else {
                    container.visibility = View.GONE
                }
            }

            // v2.0.24: AI消息文件卡片
            val fileLinkRegex = Regex("""\[文件:([^\]]+)\]\(([^)]+)\)""")
            val aiFileLinks = fileLinkRegex.findAll(msg.content).toList()
            if (aiFileLinks.isNotEmpty()) {
                holder.llImages?.let { container ->
                    container.visibility = View.VISIBLE
                    container.orientation = LinearLayout.VERTICAL
                    val dp = holder.itemView.context.resources.displayMetrics.density
                    val cardWidth = (260 * dp).toInt()
                    for (fl in aiFileLinks) {
                        val fname = fl.groupValues[1]
                        var furl = fl.groupValues[2]
                        if (furl.startsWith("/")) furl = "https://ai.xianbaba188.cn" + furl
                        val ext = fname.substringAfterLast(".", "").lowercase()
                        val icon = when(ext) { "pdf" -> "📕"; "doc","docx" -> "📘"; "xls","xlsx" -> "📗"; "ppt","pptx" -> "📊"; "zip","rar","7z" -> "📦"; "txt" -> "📝"; "mp3","wav" -> "🎵"; else -> "📄" }
                        val typeName = when(ext) { "pdf" -> "PDF"; "doc","docx" -> "Word"; "xls","xlsx" -> "Excel"; "ppt","pptx" -> "PPT"; "zip","rar","7z" -> "压缩包"; "txt" -> "文本"; "mp3","wav" -> "音频"; else -> "文件" }
                        val card = android.widget.LinearLayout(holder.itemView.context).apply {
                            orientation = android.widget.LinearLayout.HORIZONTAL
                            layoutParams = LinearLayout.LayoutParams(cardWidth, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = (4 * dp).toInt() }
                            setPadding((12 * dp).toInt(), (10 * dp).toInt(), (12 * dp).toInt(), (10 * dp).toInt())
                            background = android.graphics.drawable.GradientDrawable().apply { setColor(0x0D3B82F6); cornerRadius = (10 * dp) }
                        }
                        val iconBg = android.widget.FrameLayout(holder.itemView.context).apply {
                            layoutParams = android.widget.LinearLayout.LayoutParams((40 * dp).toInt(), (40 * dp).toInt()).apply { marginEnd = (10 * dp).toInt() }
                            background = android.graphics.drawable.GradientDrawable().apply { setColor(0x1AFF8C5A); cornerRadius = (8 * dp) }
                        }
                        val iconTv = android.widget.TextView(holder.itemView.context).apply {
                            text = icon; textSize = 22f
                            layoutParams = android.widget.FrameLayout.LayoutParams(android.widget.FrameLayout.LayoutParams.MATCH_PARENT, android.widget.FrameLayout.LayoutParams.MATCH_PARENT)
                            gravity = android.view.Gravity.CENTER
                        }
                        iconBg.addView(iconTv)
                        val infoLay = android.widget.LinearLayout(holder.itemView.context).apply {
                            orientation = android.widget.LinearLayout.VERTICAL
                            layoutParams = android.widget.LinearLayout.LayoutParams(0, android.widget.LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                        }
                        val nameTv = android.widget.TextView(holder.itemView.context).apply {
                            text = fname; textSize = 14f; setTextColor(0xFFFFFFFF.toInt()); maxLines = 1; ellipsize = android.text.TextUtils.TruncateAt.END
                        }
                        val metaTv = android.widget.TextView(holder.itemView.context).apply {
                            text = typeName; textSize = 11f; setTextColor(0x80FFFFFF.toInt())
                            layoutParams = android.widget.LinearLayout.LayoutParams(android.widget.LinearLayout.LayoutParams.WRAP_CONTENT, android.widget.LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = (2 * dp).toInt() }
                        }
                        infoLay.addView(nameTv); infoLay.addView(metaTv)
                        card.addView(iconBg); card.addView(infoLay)
                        val finalUrl = furl
                        card.setOnClickListener { openFile(holder.itemView.context, finalUrl, fname, ext) }
                        container.addView(card)
                    }
                }
            }

            // v2.0.10: AI视频 - 用ImageView缩略图替代VideoView，点击用系统播放器
            holder.vvAiVideo?.let { vv ->
                vv.visibility = View.GONE  // 隐藏VideoView
            }
            // v2.0.12: 视频缩略图+播放按钮，点击APP内全屏播放
            if (!msg.videoUrl.isNullOrEmpty()) {
                holder.llImages?.let { container ->
                    if (container.visibility != View.VISIBLE) {
                        container.visibility = View.VISIBLE
                        container.orientation = LinearLayout.VERTICAL
                    }
                    // 检查是否已添加视频缩略图
                    val existingVideoTag = container.findViewWithTag<FrameLayout>("video_thumb_frame")
                    if (existingVideoTag == null) {
                        val dp = holder.itemView.context.resources.displayMetrics.density
                        // 用FrameLayout包裹缩略图+播放按钮
                        val frame = FrameLayout(holder.itemView.context).apply {
                            tag = "video_thumb_frame"
                            layoutParams = LinearLayout.LayoutParams((220 * dp).toInt(), (140 * dp).toInt()).apply {
                                topMargin = (4 * dp).toInt()
                            }
                        }
                        // 缩略图ImageView
                        val thumb = ImageView(holder.itemView.context).apply {
                            layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT)
                            scaleType = ImageView.ScaleType.CENTER_CROP
                            setBackgroundColor(0xFF1A1A2E.toInt())
                        }
                        // 播放按钮覆盖层
                        val playBtn = ImageView(holder.itemView.context).apply {
                            layoutParams = FrameLayout.LayoutParams((48 * dp).toInt(), (48 * dp).toInt(), android.view.Gravity.CENTER)
                            setImageResource(android.R.drawable.ic_media_play)
                            setColorFilter(0xFFFFFFFF.toInt(), android.graphics.PorterDuff.Mode.SRC_IN)
                            // 半透明黑色圆形背景
                            background = android.graphics.drawable.GradientDrawable().apply {
                                setColor(0x99000000.toInt())
                                shape = android.graphics.drawable.GradientDrawable.OVAL
                            }
                            setPadding((8 * dp).toInt(), (8 * dp).toInt(), (8 * dp).toInt(), (8 * dp).toInt())
                        }
                        // v2.0.67: 缩略图优化 - 本地缓存优先，深色占位
                        try {
                            val rawThumb = if (!msg.thumbnailUrl.isNullOrEmpty()) msg.thumbnailUrl else msg.videoUrl
                            val thumbSource = if (rawThumb!!.contains(".oss-") && !rawThumb.contains("Signature")) "https://ai.xianbaba188.cn/agent/api/oss-media/" + rawThumb.split(".com/").lastOrNull() else rawThumb
                            // 深色背景占位
                            thumb.setBackgroundColor(0xFF2A2A2A.toInt())
                            thumb.setImageResource(android.R.drawable.ic_media_play)
                            // 优先从本地缓存取帧，秒出不闪
                            val videoCacheDir = File(holder.itemView.context.cacheDir, "video_cache")
                            val cacheFileName = msg.videoUrl!!.hashCode().toString() + ".mp4"
                            val localVideo = File(videoCacheDir, cacheFileName)
                            if (localVideo.exists() && localVideo.length() > 0) {
                                val requestOptions = com.bumptech.glide.request.RequestOptions()
                                    .frame(1000000)
                                    .centerCrop()
                                Glide.with(holder.itemView.context)
                                    .load(localVideo)
                                    .apply(requestOptions)
                                    .into(thumb)
                            } else if (!msg.thumbnailUrl.isNullOrEmpty()) {
                                Glide.with(holder.itemView.context)
                                    .load(thumbSource)
                                    .centerCrop()
                                    .into(thumb)
                            } else {
                                val requestOptions = com.bumptech.glide.request.RequestOptions()
                                    .frame(1000000)
                                    .centerCrop()
                                Glide.with(holder.itemView.context)
                                    .load(thumbSource)
                                    .apply(requestOptions)
                                    .into(thumb)
                            }
                        } catch (e: Exception) { android.util.Log.e("ChatActivity", "Video preload failed", e) }
                        // 点击播放：优先用本地缓存，否则用远程URL
                        frame.setOnClickListener {
                            val cacheDir = File(holder.itemView.context.cacheDir, "video_cache")
                            val fileName = msg.videoUrl!!.hashCode().toString() + ".mp4"
                            val cacheFile = File(cacheDir, fileName)
                            val playUrl = if (cacheFile.exists()) cacheFile.absolutePath else msg.videoUrl
                            val intent = Intent(holder.itemView.context, VideoPlayerActivity::class.java)
                            intent.putExtra("video_url", playUrl)
                            if (!msg.thumbnailUrl.isNullOrEmpty()) intent.putExtra("thumbnail_url", msg.thumbnailUrl)
                            holder.itemView.context.startActivity(intent)
                        }
                        frame.addView(thumb)
                        frame.addView(playBtn)
                        container.addView(frame)
                    }
                }
            }
        } else {
            val displayText = if (!msg.text.isNullOrEmpty()) msg.text else msg.content
            // v2.0.24: 有文件卡片时只显示卡片，不显示文字
            if (!msg.fileCards.isNullOrEmpty() && (displayText.isEmpty() || displayText.contains("[文件:"))) {
                holder.tvContent.visibility = View.GONE
            } else {
                holder.tvContent.text = displayText
                holder.tvContent.visibility = View.VISIBLE
            }
            // v2.0.19: 用户发的视频缩略图，每次清掉重建避免复用错误
            if (!msg.videoUrl.isNullOrEmpty()) {
                holder.llUserMedia?.let { container ->
                    container.visibility = View.VISIBLE
                    container.removeAllViews()
                    val dp = holder.itemView.context.resources.displayMetrics.density
                    val frame = FrameLayout(holder.itemView.context).apply {
                        layoutParams = LinearLayout.LayoutParams((220 * dp).toInt(), (140 * dp).toInt()).apply {
                            topMargin = (4 * dp).toInt()
                        }
                    }
                    val thumb = ImageView(holder.itemView.context).apply {
                        layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT)
                        scaleType = ImageView.ScaleType.CENTER_CROP
                        setBackgroundColor(0xFF1A1A2E.toInt())
                    }
                    val playBtn = ImageView(holder.itemView.context).apply {
                        layoutParams = FrameLayout.LayoutParams((48 * dp).toInt(), (48 * dp).toInt(), android.view.Gravity.CENTER)
                        setImageResource(android.R.drawable.ic_media_play)
                        setColorFilter(0xFFFFFFFF.toInt(), android.graphics.PorterDuff.Mode.SRC_IN)
                        background = android.graphics.drawable.GradientDrawable().apply {
                            setColor(0x99000000.toInt())
                            shape = android.graphics.drawable.GradientDrawable.OVAL
                        }
                        setPadding((8 * dp).toInt(), (8 * dp).toInt(), (8 * dp).toInt(), (8 * dp).toInt())
                    }
                    // 优先用localVideoUri本地提取帧（秒出）
                    try {
                        val localUri = msg.localVideoUri
                        if (!localUri.isNullOrEmpty() && (localUri.startsWith("content://") || localUri.startsWith("file://"))) {
                            val retriever = android.media.MediaMetadataRetriever()
                            retriever.setDataSource(holder.itemView.context, Uri.parse(localUri))
                            val bitmap = retriever.getFrameAtTime(0)
                            retriever.release()
                            if (bitmap != null) thumb.setImageBitmap(bitmap)
                        } else {
                            Glide.with(holder.itemView.context)
                                .load(msg.videoUrl)
                                .centerCrop()
                                .placeholder(android.R.drawable.ic_media_play)
                                .into(thumb)
                        }
                    } catch (e: Exception) { android.util.Log.e("ChatActivity", "Video preload failed", e) }
                    // 点击播放 - 优先用本地缓存（上传时已缓存到video_cache），其次本地URI，最后远程URL
                    frame.setOnClickListener {
                        var playUrl: String
                        val videoUrl = msg.videoUrl!!
                        val cacheDir = File(holder.itemView.context.cacheDir, "video_cache")
                        val fileName = videoUrl.substringAfterLast("/").split("?")[0]
                        val cacheFile = File(cacheDir, fileName)
                        val localUri = msg.localVideoUri
                        playUrl = when {
                            cacheFile.exists() -> cacheFile.absolutePath
                            !localUri.isNullOrEmpty() && (localUri.startsWith("content://") || localUri.startsWith("file://")) -> localUri
                            else -> videoUrl
                        }
                        val intent = Intent(holder.itemView.context, VideoPlayerActivity::class.java)
                        intent.putExtra("video_url", playUrl)
                        holder.itemView.context.startActivity(intent)
                    }
                    frame.addView(thumb)
                    frame.addView(playBtn)
                    container.addView(frame)
                }
            } else if (!msg.fileCards.isNullOrEmpty()) {
                // v2.0.25: 有文件卡片时不隐藏llUserMedia
            } else {
                holder.llUserMedia?.let { container ->
                    container.visibility = View.GONE
                    container.removeAllViews()
                }
            }

            // v2.0.24: 用户消息文件卡片（微信风格）
            if (!msg.fileCards.isNullOrEmpty()) {
                holder.llUserMedia?.let { container ->
                    container.visibility = View.VISIBLE
                    container.removeAllViews()
                    val dp = holder.itemView.context.resources.displayMetrics.density
                    val cardWidth = (240 * dp).toInt()
                    for (fc in msg.fileCards!!) {
                        val ext = fc.filename.substringAfterLast(".", "").lowercase()
                        val card = android.widget.LinearLayout(holder.itemView.context).apply {
                            orientation = android.widget.LinearLayout.HORIZONTAL
                            layoutParams = LinearLayout.LayoutParams(cardWidth, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = (4 * dp).toInt() }
                            setPadding((12 * dp).toInt(), (10 * dp).toInt(), (12 * dp).toInt(), (10 * dp).toInt())
                            background = android.graphics.drawable.GradientDrawable().apply { setColor(0xFF1E1E30.toInt()); cornerRadius = (10 * dp) }
                        }
                        val iconBg = android.widget.FrameLayout(holder.itemView.context).apply {
                            layoutParams = android.widget.LinearLayout.LayoutParams((40 * dp).toInt(), (40 * dp).toInt()).apply { marginEnd = (10 * dp).toInt() }
                            background = android.graphics.drawable.GradientDrawable().apply { setColor(0x1AFF8C5A); cornerRadius = (8 * dp) }
                        }
                        val iconTv = android.widget.TextView(holder.itemView.context).apply {
                            text = fc.icon; textSize = 22f
                            layoutParams = android.widget.FrameLayout.LayoutParams(android.widget.FrameLayout.LayoutParams.MATCH_PARENT, android.widget.FrameLayout.LayoutParams.MATCH_PARENT)
                            gravity = android.view.Gravity.CENTER
                        }
                        iconBg.addView(iconTv)
                        val infoLay = android.widget.LinearLayout(holder.itemView.context).apply {
                            orientation = android.widget.LinearLayout.VERTICAL
                            layoutParams = android.widget.LinearLayout.LayoutParams(0, android.widget.LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                        }
                        val nameTv = android.widget.TextView(holder.itemView.context).apply {
                            text = fc.filename; textSize = 14f; setTextColor(0xFFFFFFFF.toInt()); maxLines = 1; ellipsize = android.text.TextUtils.TruncateAt.END
                        }
                        val metaTv = android.widget.TextView(holder.itemView.context).apply {
                            text = fc.type; textSize = 11f; setTextColor(0x80FFFFFF.toInt())
                            layoutParams = android.widget.LinearLayout.LayoutParams(android.widget.LinearLayout.LayoutParams.WRAP_CONTENT, android.widget.LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = (2 * dp).toInt() }
                        }
                        infoLay.addView(nameTv); infoLay.addView(metaTv)
                        card.addView(iconBg); card.addView(infoLay)
                        card.setOnClickListener { openFile(holder.itemView.context, fc.url, fc.filename, ext) }
                        container.addView(card)
                    }
                }
            }

            holder.ivUserImage?.let { iv ->
                val userImgUrl = msg.imageUrl
                if (!userImgUrl.isNullOrEmpty() && msg.videoUrl.isNullOrEmpty()) {
                    iv.visibility = View.VISIBLE
                    if (userImgUrl.startsWith("content://") || userImgUrl.startsWith("file://")) {
                        iv.setImageURI(Uri.parse(userImgUrl))
                    } else {
                        Glide.with(holder.itemView.context).load(userImgUrl).into(iv)
                    }
                    iv.setOnClickListener {
                        val intent = Intent(it.context, FullscreenImageActivity::class.java)
                        intent.putExtra("image_url", userImgUrl)
                        it.context.startActivity(intent)
                    }
                } else { iv.visibility = View.GONE }
            }
        }
    }

    override fun getItemViewType(position: Int) = if (messages[position].role == "user") 0 else 1
    override fun getItemCount() = messages.size

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tvContent: TextView = itemView.findViewById(R.id.tvContent)
        val llImages: LinearLayout? = itemView.findViewById(R.id.llImages)
        val ivUserImage: ImageView? = itemView.findViewById(R.id.ivUserImage)
        val vvUserVideo: VideoView? = itemView.findViewById(R.id.vvUserVideo)
        val vvAiVideo: VideoView? = itemView.findViewById(R.id.vvAiVideo)
        val llUserMedia: LinearLayout? = itemView.findViewById(R.id.llUserMedia)
    }
}
