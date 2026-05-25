package com.chuangpu.ai.database

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class ChatDatabase(context: Context) : SQLiteOpenHelper(context, "chat_cache.db", null, 1) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                role TEXT NOT NULL,
                content TEXT NOT NULL,
                created_at INTEGER NOT NULL
            )
        """)
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_session ON messages(session_id)")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_created ON messages(created_at)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS messages")
        onCreate(db)
    }

    fun saveMessage(sessionId: String, role: String, content: String) {
        val db = writableDatabase
        val values = ContentValues().apply {
            put("session_id", sessionId)
            put("role", role)
            put("content", content)
            put("created_at", System.currentTimeMillis())
        }
        db.insert("messages", null, values)
    }

    fun getMessages(sessionId: String, limit: Int = 50): List<CachedMessage> {
        val db = readableDatabase
        val list = mutableListOf<CachedMessage>()
        val cursor = db.query("messages", null, "session_id = ?", arrayOf(sessionId), null, null, "created_at DESC", "$limit")
        cursor.use {
            while (it.moveToNext()) {
                list.add(CachedMessage(
                    sessionId = it.getString(it.getColumnIndexOrThrow("session_id")),
                    role = it.getString(it.getColumnIndexOrThrow("role")),
                    content = it.getString(it.getColumnIndexOrThrow("content")),
                    createdAt = it.getLong(it.getColumnIndexOrThrow("created_at"))
                ))
            }
        }
        return list
    }

    fun getAllFileMessages(limit: Int = 200): List<CachedMessage> {
        val db = readableDatabase
        val list = mutableListOf<CachedMessage>()
        // 只查包含文件链接或[文件:xxx]的消息
        val cursor = db.query("messages", null,
            "content LIKE '%.pdf%' OR content LIKE '%.doc%' OR content LIKE '%.xls%' OR content LIKE '%.zip%' OR content LIKE '%.rar%' OR content LIKE '%[文件:%' OR content LIKE '%.txt%' OR content LIKE '%.csv%' OR content LIKE '%.ppt%'",
            null, null, null, "created_at DESC", "$limit")
        cursor.use {
            while (it.moveToNext()) {
                list.add(CachedMessage(
                    sessionId = it.getString(it.getColumnIndexOrThrow("session_id")),
                    role = it.getString(it.getColumnIndexOrThrow("role")),
                    content = it.getString(it.getColumnIndexOrThrow("content")),
                    createdAt = it.getLong(it.getColumnIndexOrThrow("created_at"))
                ))
            }
        }
        return list
    }

    fun clearSession(sessionId: String) {
        writableDatabase.delete("messages", "session_id = ?", arrayOf(sessionId))
    }

    data class CachedMessage(
        val sessionId: String,
        val role: String,
        val content: String,
        val createdAt: Long
    )
}
