package com.chuangpu.ai.ui.chat

import android.net.Uri
import android.os.Bundle
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.VideoView
import android.widget.MediaController
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.bumptech.glide.Glide
import com.chuangpu.ai.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.net.URL

class VideoPlayerActivity : AppCompatActivity() {

    private var videoView: VideoView? = null
    private var pbLoading: ProgressBar? = null
    private var ivThumb: ImageView? = null
    private var tvStatus: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_video_player_native)

        videoView = findViewById(R.id.vvPlayer)
        pbLoading = findViewById(R.id.pbLoading)
        ivThumb = findViewById(R.id.ivThumb)
        tvStatus = findViewById(R.id.tvStatus)
        val ivClose = findViewById<ImageView>(R.id.ivClose)

        var videoUrl = intent.getStringExtra("video_url") ?: run { finish(); return }
        val thumbnailUrl = intent.getStringExtra("thumbnail_url")

        ivClose.setOnClickListener { finish() }

        if (!thumbnailUrl.isNullOrEmpty()) {
            try { Glide.with(this).load(thumbnailUrl).centerCrop().into(ivThumb!!) } catch (_: Exception) {}
        }
        ivThumb?.visibility = ImageView.VISIBLE
        pbLoading?.visibility = ProgressBar.VISIBLE
        tvStatus?.visibility = TextView.VISIBLE
        tvStatus?.text = "加载中..."

        // content:// 本地URI，直接秒开（用户上传的视频本地已有）
        if (videoUrl.startsWith("content://")) {
            playContentUri(videoUrl)
            return
        }

        // 已经是本地文件，直接秒开
        if (videoUrl.startsWith("/") || videoUrl.startsWith("file://")) {
            val file = File(videoUrl.replace("file://", ""))
            if (file.exists()) {
                playLocal(file)
                return
            }
        }

        // OSS原始URL转代理URL
        if (videoUrl.contains(".oss-") && !videoUrl.contains("Signature") && !videoUrl.contains("Expires")) {
            val ossKey = videoUrl.split(".com/").lastOrNull() ?: ""
            if (ossKey.isNotEmpty()) {
                videoUrl = "https://ai.xianbaba188.cn/agent/api/oss-media/" + ossKey
            }
        }

        // 查本地缓存
        val cacheDir = File(cacheDir, "video_cache")
        if (!cacheDir.exists()) cacheDir.mkdirs()
        val cacheFileName = videoUrl.hashCode().toString() + ".mp4"
        val cacheFile = File(cacheDir, cacheFileName)

        if (cacheFile.exists() && cacheFile.length() > 0) {
            playLocal(cacheFile)
        } else {
            playStream(videoUrl, cacheFile)
        }
    }

    private fun playStream(url: String, cacheFile: File) {
        val mediaController = MediaController(this)
        mediaController.setAnchorView(videoView)
        videoView?.setMediaController(mediaController)
        videoView?.setOnPreparedListener {
            ivThumb?.visibility = ImageView.GONE
            tvStatus?.visibility = TextView.GONE
            pbLoading?.visibility = ProgressBar.GONE
        }
        videoView?.setOnErrorListener { _, _, _ ->
            tvStatus?.text = "播放失败"
            pbLoading?.visibility = ProgressBar.GONE
            false
        }
        videoView?.setVideoURI(Uri.parse(url))
        videoView?.start()

        // 后台缓存，下次秒开
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val conn = URL(url).openConnection()
                conn.connectTimeout = 15000
                conn.readTimeout = 30000
                conn.setRequestProperty("User-Agent", "Mozilla/5.0")
                val input = conn.getInputStream()
                val tmpFile = File(cacheFile.parent, cacheFile.name + ".tmp")
                val output = java.io.FileOutputStream(tmpFile)
                val buf = ByteArray(8192)
                var n: Int
                while (input.read(buf).also { n = it } != -1) {
                    output.write(buf, 0, n)
                }
                output.flush()
                output.close()
                input.close()
                tmpFile.renameTo(cacheFile)
            } catch (_: Exception) {}
        }
    }

    private fun playContentUri(uriStr: String) {
        tvStatus?.visibility = TextView.GONE
        pbLoading?.visibility = ProgressBar.GONE
        val mediaController = MediaController(this)
        mediaController.setAnchorView(videoView)
        videoView?.setMediaController(mediaController)
        videoView?.setOnPreparedListener {
            ivThumb?.visibility = ImageView.GONE
        }
        videoView?.setVideoURI(Uri.parse(uriStr))
        videoView?.start()
    }

    private fun playLocal(file: File) {
        tvStatus?.visibility = TextView.GONE
        pbLoading?.visibility = ProgressBar.GONE
        val mediaController = MediaController(this)
        mediaController.setAnchorView(videoView)
        videoView?.setMediaController(mediaController)
        videoView?.setOnPreparedListener {
            ivThumb?.visibility = ImageView.GONE
        }
        videoView?.setVideoURI(Uri.fromFile(file))
        videoView?.start()
    }

    override fun onPause() { super.onPause(); videoView?.pause() }
    override fun onResume() { super.onResume() }
    override fun onDestroy() { super.onDestroy(); videoView?.stopPlayback() }
    override fun onBackPressed() { finish() }
}
