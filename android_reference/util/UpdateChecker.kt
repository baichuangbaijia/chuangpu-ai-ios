package com.chuangpu.ai.util

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.core.content.FileProvider
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.util.concurrent.TimeUnit

data class VersionInfo(
    val version_code: Int = 0,
    val version_name: String = "",
    val download_url: String = "",
    val update_log: String = ""
)

object UpdateChecker {
    private const val VERSION_URL = "https://ai.xianbaba188.cn/version.json"

    fun getCurrentVersionCode(context: Context): Int {
        return try {
            context.packageManager.getPackageInfo(context.packageName, 0).let {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                    it.longVersionCode.toInt()
                } else {
                    @Suppress("DEPRECATION")
                    it.versionCode
                }
            }
        } catch (e: Exception) { 1 }
    }

    suspend fun check(context: Context, silent: Boolean = true) {
        withContext(Dispatchers.IO) {
            try {
                val client = OkHttpClient.Builder()
                    .connectTimeout(10, TimeUnit.SECONDS)
                    .readTimeout(10, TimeUnit.SECONDS)
                    .build()
                val request = Request.Builder().url(VERSION_URL).get().build()
                val response = client.newCall(request).execute()
                val body = response.body?.string()
                Log.d("UpdateChecker", "version.json response: " + body)
                if (body == null) return@withContext
                val info = Gson().fromJson(body, VersionInfo::class.java)

                val currentCode = getCurrentVersionCode(context)
                Log.d("UpdateChecker", "remote version_code=" + info.version_code + " local currentCode=" + currentCode)
                if (info.version_code > currentCode) {
                    withContext(Dispatchers.Main) {
                        showUpdateDialog(context, info)
                    }
                } else if (!silent) {
                    withContext(Dispatchers.Main) {
                        Toast.makeText(context, "已是最新版本", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                Log.e("UpdateChecker", "check update failed", e)
                if (!silent) {
                    withContext(Dispatchers.Main) {
                        Toast.makeText(context, "检查更新失败", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }
    }

    private fun showUpdateDialog(context: Context, info: VersionInfo) {
        AlertDialog.Builder(context)
            .setTitle("发现新版本 v" + info.version_name)
            .setMessage(info.update_log)
            .setPositiveButton("立即更新") { _, _ ->
                downloadAndInstall(context, info.download_url, info.version_code)
            }
            .setNegativeButton("稍后再说", null)
            .setCancelable(true)
            .show()
    }

    private fun clearOldDownloads(context: Context) {
        try {
            val downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val cursor = downloadManager.query(DownloadManager.Query())
            val idColumn = cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_ID)
            val uriColumn = cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_LOCAL_URI)
            while (cursor.moveToNext()) {
                val localUri = cursor.getString(uriColumn)
                if (localUri != null && localUri.contains("cp-update")) {
                    val id = cursor.getLong(idColumn)
                    downloadManager.remove(id)
                    Log.d("UpdateChecker", "Removed old download id=")
                }
            }
            cursor.close()
        } catch (e: Exception) {
            Log.e("UpdateChecker", "clearOldDownloads failed", e)
        }
    }

    private fun downloadAndInstall(context: Context, url: String, versionCode: Int) {
        try {
            // 清理DownloadManager里旧的下载记录
            clearOldDownloads(context)

            // 清理本地旧APK文件
            val updateDir = context.getExternalFilesDir(null)
            updateDir?.listFiles()?.filter { it.name.startsWith("cp-update") }?.forEach {
                it.delete()
                Log.d("UpdateChecker", "Deleted old file: " + it.name)
            }

            // 用版本号命名避免冲突
            val fileName = "cp-update-${versionCode}.apk"
            val file = File(updateDir, fileName)

            val downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val request = DownloadManager.Request(Uri.parse(url))
            request.setTitle("创普AI更新")
            request.setDescription("正在下载新版本...")
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            request.setMimeType("application/vnd.android.package-archive")
            request.setDestinationUri(Uri.fromFile(file))

            val downloadId = downloadManager.enqueue(request)

            val progressBar = ProgressBar(context, null, android.R.attr.progressBarStyleHorizontal)
            progressBar.max = 100
            progressBar.progress = 0
            val progressText = TextView(context).apply {
                text = "准备下载... 0%"
                setTextColor(-0x1)
                textSize = 14f
                setPadding(0, 16, 0, 0)
            }
            val dialogView = android.widget.LinearLayout(context).apply {
                orientation = android.widget.LinearLayout.VERTICAL
                setPadding(48, 24, 48, 16)
                addView(progressBar)
                addView(progressText)
            }
            val dialog = AlertDialog.Builder(context)
                .setTitle("正在下载更新")
                .setView(dialogView)
                .setCancelable(false)
                .create()
            dialog.show()

            val handler = Handler(Looper.getMainLooper())
            val pollRunnable = object : Runnable {
                override fun run() {
                    val query = DownloadManager.Query().setFilterById(downloadId)
                    val cursor: Cursor = downloadManager.query(query)
                    if (cursor.moveToFirst()) {
                        val bytesDownloaded = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
                        val bytesTotal = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
                        val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                        if (bytesTotal > 0) {
                            val progress = (bytesDownloaded * 100 / bytesTotal).toInt()
                            progressBar.progress = progress
                            progressText.text = "已下载 $progress% (${bytesDownloaded / 1024}KB / ${bytesTotal / 1024}KB)"
                        }
                        if (status == DownloadManager.STATUS_SUCCESSFUL) {
                            cursor.close()
                            dialog.dismiss()
                            // 验证文件完整性
                            if (!file.exists() || file.length() < 100000) {
                                Toast.makeText(context, "下载文件异常(" + file.length() + "字节)，请重试", Toast.LENGTH_LONG).show()
                                return
                            }
                            try {
                                val apkUri = FileProvider.getUriForFile(context, context.packageName + ".fileprovider", file)
                                val installIntent = Intent(Intent.ACTION_VIEW)
                                installIntent.setDataAndType(apkUri, "application/vnd.android.package-archive")
                                installIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                installIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                context.startActivity(installIntent)
                            } catch (e: Exception) {
                                Toast.makeText(context, "安装失败: " + e.message, Toast.LENGTH_LONG).show()
                            }
                            return
                        } else if (status == DownloadManager.STATUS_FAILED) {
                            cursor.close()
                            dialog.dismiss()
                            val reason = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
                            Toast.makeText(context, "下载失败(错误码:$reason)，请重试", Toast.LENGTH_LONG).show()
                            return
                        }
                    }
                    cursor.close()
                    handler.postDelayed(this, 500)
                }
            }
            handler.postDelayed(pollRunnable, 500)

        } catch (e: Exception) {
            Toast.makeText(context, "下载失败: " + e.message, Toast.LENGTH_LONG).show()
        }
    }
}
