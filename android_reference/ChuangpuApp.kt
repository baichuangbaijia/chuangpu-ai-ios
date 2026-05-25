package com.chuangpu.ai

import android.app.Application
import android.os.Process

class ChuangpuApp : Application() {
    companion object {
        var instance: ChuangpuApp? = null
    }
    override fun onCreate() {
        instance = this
        super.onCreate()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            // 崩溃直接杀进程，不要重启循环
            Process.killProcess(Process.myPid())
        }
    }
}
