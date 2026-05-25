package com.chuangpu.ai.network

import android.content.Context
import com.chuangpu.ai.model.*
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import android.util.Log
import android.net.Uri
import java.io.InputStream
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException

class ApiService(private val context: Context) {
    private val client get() = ApiClient.getClient(context)
    private val sseClient get() = ApiClient.getSseClient(context)
    private val gson = Gson()
    private val baseUrl = "https://ai.xianbaba188.cn/api/"
    
    private fun checkVipResponse(json: String?) {
        if (json != null && json.contains("1001")) {
            try {
                val result = gson.fromJson(json, ApiResult::class.java)
                if (result.code == 1001) {
                    val intent = android.content.Intent("com.chuangpu.ai.ACTION_VIP_REQUIRED")
                    intent.setPackage(null)
                    context.sendBroadcast(intent)
                }
            } catch (_: Exception) {}
        }
    }

    // 发送短信验证码
    suspend fun sendSmsCode(phone: String, type: String): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val body = mapOf("phone" to phone, "type" to type)
            val request = Request.Builder()
                .url(baseUrl + "auth/sms-code")
                .post(gson.toJson(body).toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Any>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 登录
    suspend fun login(phone: String, code: String? = null, password: String? = null, loginType: String = "sms"): ApiResult<LoginData>? = withContext(Dispatchers.IO) {
        try {
            val body = mutableMapOf<String, Any>("phone" to phone)
            if (loginType == "sms" && code != null) body["code"] = code
            if (loginType == "pwd" && password != null) body["password"] = password
            // Vue: pwd login does not send type field
        if (loginType == "sms") body["type"] = loginType
            
            val request = Request.Builder()
                .url(baseUrl + "auth/login")
                .post(gson.toJson(body).toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            Log.d("ApiService", "Login response: code=${response.code}, body=$responseBody")
            if (responseBody != null) {
                // 后端错误返回 {detail:xxx} 格式，正常返回 {code:0,message:xxx,data:{...}}
                try {
                    val errorObj = gson.fromJson(responseBody, Map::class.java)
                    if (errorObj.containsKey("detail")) {
                        // 错误响应，提取detail作为message
                        val detail = errorObj["detail"] as? String ?: "操作失败"
                        ApiResult<LoginData>(-1, null, detail)
                    } else {
                        gson.fromJson<ApiResult<LoginData>>(responseBody, object : TypeToken<ApiResult<LoginData>>() {}.type)
                    }
                } catch (e: Exception) {
                    gson.fromJson<ApiResult<LoginData>>(responseBody, object : TypeToken<ApiResult<LoginData>>() {}.type)
                }
            } else null
        } catch (e: Exception) { Log.e("ApiService", "Login error", e); null }
    }

    // 注册
    suspend fun register(phone: String, password: String, code: String): ApiResult<LoginData>? = withContext(Dispatchers.IO) {
        try {
            val body = mapOf("phone" to phone, "password" to password, "code" to code)
            val request = Request.Builder()
                .url(baseUrl + "auth/register")
                .post(gson.toJson(body).toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<LoginData>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 获取用户信息
    suspend fun getMe(): ApiResult<User>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "auth/me")
                .get()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<User>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 更新用户信息
    suspend fun updateProfile(nickname: String): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val body = mapOf("nickname" to nickname)
            val request = Request.Builder()
                .url(baseUrl + "auth/profile")
                .put(gson.toJson(body).toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Any>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 获取会话列表 - 对照Vue api.js: fetch(/agent/api/chat/conversations)
    // /agent/api 返回 {code:0, data:[...]} data直接是list，不是data.list
    suspend fun getConversations(): ApiListResult<Conversation>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("https://ai.xianbaba188.cn/agent/api/chat/conversations")
                .get()
                .build()
            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            Log.d("ApiService", "Conversations response: code=" + response.code + " body=" + responseBody)
            if (response.code == 403 || response.code == 401) {
                checkVipResponse(responseBody)
                return@withContext null
            }
            if (responseBody != null) {
                try {
                    val root = gson.fromJson(responseBody, Map::class.java) as? Map<*, *>
                    val code = (root?.get("code") as? Number)?.toInt() ?: -1
                    val msg = root?.get("message") as? String
                    val dataObj = root?.get("data")
                    if (code == 0 && dataObj != null) {
                        val convList: List<Conversation> = gson.fromJson(gson.toJson(dataObj), object : TypeToken<List<Conversation>>() {}.type)
                        ApiListResult(code, ListData(convList, convList.size, 1, 20), msg)
                    } else {
                        ApiListResult(code, null, msg)
                    }
                } catch (e: Exception) {
                    Log.e("ApiService", "Conversations parse error", e)
                    null
                }
            } else null
        } catch (e: Exception) {
            Log.e("ApiService", "Conversations request error", e)
            null
        }
    }

    // 创建会话 - 对照Vue api.js: /agent/api/chat/conversations
    suspend fun createConversation(): ApiResult<Conversation>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("https://ai.xianbaba188.cn/agent/api/chat/conversations")
                .post("{}".toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            val rawBody = response.body?.string()
            android.util.Log.d("ApiService", "createConversation raw=$rawBody")
            if (response.code == 403 || response.code == 401) {
                checkVipResponse(rawBody)
                return@withContext null
            }
            if (response.code == 403 || response.code == 401) {
                checkVipResponse(rawBody)
                return@withContext null
            }
            if (rawBody != null) {
                try {
                    gson.fromJson<ApiResult<Conversation>>(rawBody, object : TypeToken<ApiResult<Conversation>>() {}.type)
                } catch (e2: Exception) {
                    android.util.Log.e("ApiService", "createConversation parse error", e2)
                    null
                }
            } else null
        } catch (e: Exception) {
            android.util.Log.e("ApiService", "createConversation request error", e)
            null
        }
    }

    // 删除会话 - 对照Vue: /agent/api/chat/conversations/:id
    suspend fun deleteConversation(id: Long): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("https://ai.xianbaba188.cn/agent/api/chat/conversations/$id")
                .delete()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Any>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 发送消息（SSE流式）- 对照Vue: processQueue中的SSE解析
    fun sendMessageSse(
        sessionId: String?,
        message: String,
        model: String,
        images: List<String> = emptyList(),
        videos: List<String> = emptyList(),
        onChunk: (type: String, content: String, thumbnail: String) -> Unit,
        onComplete: () -> Unit,
        onError: (String) -> Unit
    ): Call {
        val body = mutableMapOf<String, Any>("message" to message, "model" to model)
        if (!sessionId.isNullOrEmpty()) body["session_id"] = sessionId
        if (images.isNotEmpty()) body["images"] = images
        if (videos.isNotEmpty()) body["videos"] = videos
        
        val request = Request.Builder()
            .url("https://ai.xianbaba188.cn/agent/api/chat/stream")
            .post(gson.toJson(body).toRequestBody("application/json".toMediaType()))
            .build()
        
        val call = sseClient.newCall(request)
        call.enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                onError(e.message ?: "请求失败")
            }
            override fun onResponse(call: Call, response: Response) {
                try {
                    val source = response.body?.source() ?: run { onError("空响应"); return }
                    while (!source.exhausted()) {
                        val line = source.readUtf8Line() ?: continue
                        if (line.startsWith("data:")) {
                            val data = line.substringAfter("data:").trim()
                            if (data.isNotEmpty() && data != "[DONE]") {
                                try {
                                    val chunkData = gson.fromJson(data, Map::class.java) as? Map<*, *>
                                    if (chunkData != null) {
                                        val type = chunkData["type"] as? String ?: ""
                                        val content = chunkData["content"] as? String ?: ""
                                        val url = chunkData["url"] as? String ?: ""
                                        val error = chunkData["error"] as? String
                                        if (error != null) {
                                            onError(error)
                                            return
                                        } else if ((type == "image" || type == "video") && url.isNotEmpty()) {
                                            // v2.0.14: video event also has thumbnail
                                            val thumbnail = chunkData["thumbnail"] as? String ?: ""
                                            onChunk(type, url, thumbnail)
                                        } else if (content.isNotEmpty()) {
                                            onChunk(type, content, "")
                                        }
                                    }
                                } catch (_: Exception) { }
                            }
                        }
                    }
                    onComplete()
                } catch (e: Exception) {
                    onError(e.message ?: "连接异常")
                }
            }
        })
        return call
    }

    // 获取积分余额
    suspend fun getCreditBalance(): ApiResult<CreditData>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "credit/balance")
                .get()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<CreditData>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 获取技能列表 - 手动解析避免泛型擦除问题
    suspend fun searchSkills(params: Map<String, Any>): ApiListResult<Skill>? = withContext(Dispatchers.IO) {
        try {
            val query = params.entries.joinToString("&") { "${it.key}=${it.value}" }
            val url = baseUrl + "skills/search?$query"
            Log.d("ApiService", "searchSkills URL: $url")
            val request = Request.Builder()
                .url(url)
                .get()
                .build()
            val response = client.newCall(request).execute()
            val body = response.body?.string()
            Log.d("ApiService", "searchSkills response code=${response.code}, body=${body?.take(200)}")
            if (body != null) {
                try {
                    val root = gson.fromJson(body, Map::class.java) as? Map<*, *>
                    val code = (root?.get("code") as? Number)?.toInt() ?: -1
                    val msg = root?.get("message") as? String
                    val dataObj = root?.get("data") as? Map<*, *>
                    val total = (dataObj?.get("total") as? Number)?.toInt() ?: 0
                    val page = (dataObj?.get("page") as? Number)?.toInt() ?: 1
                    val limit = (dataObj?.get("limit") as? Number)?.toInt() ?: 20
                    val listObj = dataObj?.get("list")
                    val skills: List<Skill> = if (listObj != null) {
                        gson.fromJson(gson.toJson(listObj), object : TypeToken<List<Skill>>() {}.type)
                    } else emptyList()
                    Log.d("ApiService", "searchSkills parsed: code=$code, total=$total, listSize=${skills.size}, first=${skills.firstOrNull()?.name}, slug=${skills.firstOrNull()?.slug}")
                    ApiListResult(code, ListData(skills, total, page, limit), msg)
                } catch (e: Exception) {
                    Log.e("ApiService", "searchSkills parse error", e)
                    null
                }
            } else null
        } catch (e: Exception) {
            Log.e("ApiService", "searchSkills request error", e)
            null
        }
    }

    // 获取技能详情
    suspend fun getSkillDetail(slug: String): ApiResult<Skill>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "skills/detail/$slug")
                .get()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Skill>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 获取服务端已安装技能
    suspend fun getServerInstalled(): ApiResult<InstalledData>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "skill/installed/my")
                .get()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<InstalledData>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 获取我的技能
    suspend fun getMySkills(): ApiResult<MySkillsData>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "skill/installed/my")
                .get()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<MySkillsData>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 获取AI记忆列表
    suspend fun getMemoryList(page: Int, pageSize: Int, keyword: String): ApiResult<MemoryListData>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "memory/list?page=$page&pageSize=$pageSize&keyword=$keyword")
                .get()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<MemoryListData>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 获取记忆详情
    suspend fun getMemoryDetail(id: String): ApiResult<Memory>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "memory/detail/$id")
                .get()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Memory>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 更新记忆
    suspend fun updateMemory(id: String, content: String): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val body = mapOf("content" to content)
            val request = Request.Builder()
                .url(baseUrl + "memory/update/$id")
                .put(gson.toJson(body).toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Any>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 删除记忆
    suspend fun deleteMemory(id: String): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "memory/delete/$id")
                .delete()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Any>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 获取定时任务列表
    suspend fun getTaskList(): ApiResult<TaskListData>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "task/list")
                .get()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<TaskListData>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 创建定时任务
    suspend fun createTask(data: Map<String, Any>): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "task/create")
                .post(gson.toJson(data).toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Any>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 更新定时任务
    suspend fun updateTask(id: Long, data: Map<String, Any>): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "task/update/$id")
                .put(gson.toJson(data).toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Any>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 删除定时任务
    suspend fun deleteTask(id: Long): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "task/delete/$id")
                .delete()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Any>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 暂停任务
    suspend fun pauseTask(id: Long): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "task/pause/$id")
                .post("{}".toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Any>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 恢复任务
    suspend fun resumeTask(id: Long): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "task/resume/$id")
                .post("{}".toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<Any>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 对照Vue: loadChatHistoryFromBridge
    // /agent/api/chat/history 返回格式: {"messages": [{role, content, created_at}, ...]}
    // 不是标准的 {code:0, data:{list:[...]}} 格式
    suspend fun getChatHistory(sessionId: String): List<HistoryMessage>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("https://ai.xianbaba188.cn/agent/api/chat/history?session_id=" + sessionId)
                .get()
                .build()
            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            Log.d("ApiService", "ChatHistory response: code=" + response.code + " body=" + responseBody?.take(200))
            if (responseBody != null) {
                try {
                    val root = gson.fromJson(responseBody, Map::class.java) as? Map<*, *>
                    val messagesObj = root?.get("messages")
                    if (messagesObj != null) {
                        gson.fromJson<List<HistoryMessage>>(gson.toJson(messagesObj), object : TypeToken<List<HistoryMessage>>() {}.type)
                    } else null
                } catch (e: Exception) {
                    Log.e("ApiService", "ChatHistory parse error", e)
                    null
                }
            } else null
        } catch (e: Exception) {
            Log.e("ApiService", "ChatHistory request error", e)
            null
        }
    }

    // v4.9.4: Get raw history with is_generating flag
    suspend fun getChatHistoryRaw(sessionId: String): Map<String, Any?>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("https://ai.xianbaba188.cn/agent/api/chat/history?session_id=" + sessionId)
                .get()
                .build()
            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            if (responseBody != null) {
                try {
                    gson.fromJson(responseBody, Map::class.java) as? Map<String, Any?>
                } catch (e: Exception) { null }
            } else null
        } catch (e: Exception) { null }
    }

    // 获取子任务列表
    suspend fun getSubtasks(conversationId: Long): ApiResult<List<Subtask>>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("https://ai.xianbaba188.cn/agent/api/chat/conversations/$conversationId/subtasks")
                .get()
                .build()
            val response = client.newCall(request).execute()
            ApiClient.parseResponse(response, object : TypeToken<ApiResult<List<Subtask>>>() {}.type)
        } catch (e: Exception) { null }
    }

    // v5.2: 上传视频到专用接口
    suspend fun doUploadVideo(file: java.io.File, mimeType: String, onProgress: (Int) -> Unit = {}): String? = withContext(Dispatchers.IO) {
        try {
            android.util.Log.e("UploadVideo", "Starting upload: file=" + file.absolutePath + " size=" + file.length() + " mime=" + mimeType)
            onProgress(5)
            val totalBytes = file.length()
            val fileBody = object : okhttp3.RequestBody() {
                override fun contentType(): okhttp3.MediaType? = mimeType.toMediaType()
                override fun contentLength(): Long = totalBytes
                override fun writeTo(sink: okio.BufferedSink) {
                    val input = java.io.FileInputStream(file)
                    val buf = ByteArray(8192)
                    var totalWritten = 0L
                    var lastReportedPct = 0
                    var read: Int
                    while (input.read(buf).also { read = it } != -1) {
                        sink.write(buf, 0, read)
                        totalWritten += read.toInt()
                        if (totalBytes > 0) {
                            val pct = (totalWritten * 85 / totalBytes).toInt()
                            if (pct - lastReportedPct >= 5) {
                                lastReportedPct = pct
                                onProgress(pct)
                            }
                        }
                    }
                    input.close()
                }
            }
            val requestBody = okhttp3.MultipartBody.Part.createFormData(
                "file", file.name, fileBody
            )
            val token = com.chuangpu.ai.util.PreferencesManager.getInstance(context).getToken() ?: ""
            val uploadBaseUrl = "https://ai.xianbaba188.cn/upload-api/"
            val uploadClient = okhttp3.OkHttpClient.Builder()
                .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
                .readTimeout(120, java.util.concurrent.TimeUnit.SECONDS)
                .writeTimeout(120, java.util.concurrent.TimeUnit.SECONDS)
                .build()
            onProgress(88)
            val request = okhttp3.Request.Builder()
                .url(uploadBaseUrl + "video")
                .addHeader("Authorization", "Bearer $token")
                .post(okhttp3.MultipartBody.Builder()
                    .setType(okhttp3.MultipartBody.FORM)
                    .addPart(requestBody)
                    .build())
                .build()
            val response = uploadClient.newCall(request).execute()
            android.util.Log.e("UploadVideo", "Response: code=" + response.code + " msg=" + response.message)
            if (response.isSuccessful) {
                val body = response.body?.string()
                android.util.Log.e("UploadVideo", "Body: " + body)
                val json = org.json.JSONObject(body ?: "")
                if (json.optInt("code") == 0) {
                    onProgress(95)
                    json.optJSONObject("data")?.optString("url")
                } else {
                    android.util.Log.e("UploadVideo", "Server error: " + json.optString("message"))
                    null
                }
            } else {
                android.util.Log.e("UploadVideo", "HTTP error: " + response.code)
                null
            }
        } catch (e: Exception) {
            android.util.Log.e("UploadVideo", "FAILED: " + e.message, e)
            null
        }
    }




    suspend fun uploadImageFromUri(uri: android.net.Uri, mimeType: String, fileName: String, onProgress: (Int) -> Unit = {}): String? = withContext(Dispatchers.IO) {
        try {
            onProgress(10)
            val token = com.chuangpu.ai.util.PreferencesManager.getInstance(context).getToken() ?: ""
            val uploadBaseUrl = "https://ai.xianbaba188.cn/upload-api/"
            val inputStream = context.contentResolver.openInputStream(uri) ?: return@withContext null
            val fileBody = object : okhttp3.RequestBody() {
                override fun contentType(): okhttp3.MediaType? = mimeType.toMediaType()
                override fun contentLength(): Long = -1
                override fun writeTo(sink: okio.BufferedSink) {
                    val buf = ByteArray(8192)
                    var read: Int
                    while (inputStream.read(buf).also { read = it } != -1) {
                        sink.write(buf, 0, read)
                    }
                    inputStream.close()
                }
            }
            val requestBody = okhttp3.MultipartBody.Part.createFormData("file", fileName, fileBody)
            val uploadClient = okhttp3.OkHttpClient.Builder()
                .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
                .readTimeout(60, java.util.concurrent.TimeUnit.SECONDS)
                .writeTimeout(60, java.util.concurrent.TimeUnit.SECONDS)
                .build()
            onProgress(30)
            val request = okhttp3.Request.Builder()
                .url(uploadBaseUrl + "image")
                .addHeader("Authorization", "Bearer $token")
                .post(okhttp3.MultipartBody.Builder()
                    .setType(okhttp3.MultipartBody.FORM)
                    .addPart(requestBody)
                    .build())
                .build()
            val response = uploadClient.newCall(request).execute()
            if (response.isSuccessful) {
                val body = response.body?.string()
                val json = org.json.JSONObject(body ?: "")
                if (json.optInt("code") == 0) {
                    onProgress(90)
                    json.optJSONObject("data")?.optString("url")
                } else null
            } else null
        } catch (e: Exception) {
            null
        }
    }

    suspend fun uploadFileFromUri(uri: android.net.Uri, mimeType: String, fileName: String, onProgress: (Int) -> Unit = {}): String? = withContext(Dispatchers.IO) {
        try {
            onProgress(10)
            val token = com.chuangpu.ai.util.PreferencesManager.getInstance(context).getToken() ?: ""
            val uploadBaseUrl = "https://ai.xianbaba188.cn/upload-api/"
            val inputStream = context.contentResolver.openInputStream(uri) ?: return@withContext null
            val fileBody = object : okhttp3.RequestBody() {
                override fun contentType(): okhttp3.MediaType? = mimeType.toMediaType()
                override fun contentLength(): Long = -1
                override fun writeTo(sink: okio.BufferedSink) {
                    val buf = ByteArray(8192)
                    var read: Int
                    while (inputStream.read(buf).also { read = it } != -1) {
                        sink.write(buf, 0, read)
                    }
                    inputStream.close()
                }
            }
            val requestBody = okhttp3.MultipartBody.Part.createFormData("file", fileName, fileBody)
            val uploadClient = okhttp3.OkHttpClient.Builder()
                .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
                .readTimeout(120, java.util.concurrent.TimeUnit.SECONDS)
                .writeTimeout(120, java.util.concurrent.TimeUnit.SECONDS)
                .build()
            onProgress(30)
            val request = okhttp3.Request.Builder()
                .url(uploadBaseUrl + "file")
                .addHeader("Authorization", "Bearer $token")
                .post(okhttp3.MultipartBody.Builder()
                    .setType(okhttp3.MultipartBody.FORM)
                    .addPart(requestBody)
                    .build())
                .build()
            val response = uploadClient.newCall(request).execute()
            if (response.isSuccessful) {
                val body = response.body?.string()
                val json = org.json.JSONObject(body ?: "")
                if (json.optInt("code") == 0) {
                    onProgress(90)
                    json.optJSONObject("data")?.optString("url")
                } else null
            } else null
        } catch (e: Exception) {
            Log.e("UploadFile", "FAILED: " + e.message, e)
            null
        }
    }

    suspend fun doUploadVideoFromUri(uri: android.net.Uri, mimeType: String, fileName: String, onProgress: (Int) -> Unit = {}): String? = withContext(Dispatchers.IO) {
        try {
            Log.e("UploadVideo", "Starting upload from URI: $uri mime=$mimeType")
            onProgress(5)
            val token = com.chuangpu.ai.util.PreferencesManager.getInstance(context).getToken() ?: ""
            val uploadBaseUrl = "https://ai.xianbaba188.cn/upload-api/"
            val inputStream = context.contentResolver.openInputStream(uri) ?: return@withContext null
            // Get file size from content resolver
            var fileSize = 0L
            context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val sizeIndex = cursor.getColumnIndex(android.provider.OpenableColumns.SIZE)
                    if (sizeIndex >= 0) fileSize = cursor.getLong(sizeIndex)
                }
            }
            Log.e("UploadVideo", "File size from resolver: $fileSize bytes")
            if (fileSize > 50 * 1024 * 1024) {
                Log.e("UploadVideo", "File too large: $fileSize")
                return@withContext null
            }
            val fileBody = object : okhttp3.RequestBody() {
                override fun contentType(): okhttp3.MediaType? = mimeType.toMediaType()
                override fun contentLength(): Long = fileSize
                override fun writeTo(sink: okio.BufferedSink) {
                    val buf = ByteArray(8192)
                    var totalWritten = 0L
                    var lastReportedPct = 0
                    var read: Int
                    while (inputStream.read(buf).also { read = it } != -1) {
                        sink.write(buf, 0, read)
                        totalWritten += read.toInt()
                        if (fileSize > 0) {
                            val pct = (totalWritten * 85 / fileSize).toInt()
                            if (pct - lastReportedPct >= 5) {
                                lastReportedPct = pct
                                onProgress(pct)
                            }
                        }
                    }
                    inputStream.close()
                }
            }
            val requestBody = okhttp3.MultipartBody.Part.createFormData("file", fileName, fileBody)
            val uploadClient = okhttp3.OkHttpClient.Builder()
                .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
                .readTimeout(120, java.util.concurrent.TimeUnit.SECONDS)
                .writeTimeout(120, java.util.concurrent.TimeUnit.SECONDS)
                .build()
            onProgress(88)
            val request = okhttp3.Request.Builder()
                .url(uploadBaseUrl + "video")
                .addHeader("Authorization", "Bearer $token")
                .post(okhttp3.MultipartBody.Builder()
                    .setType(okhttp3.MultipartBody.FORM)
                    .addPart(requestBody)
                    .build())
                .build()
            val response = uploadClient.newCall(request).execute()
            Log.e("UploadVideo", "Response: code=" + response.code)
            if (response.isSuccessful) {
                val body = response.body?.string()
                Log.e("UploadVideo", "Body: " + body)
                val json = org.json.JSONObject(body ?: "")
                if (json.optInt("code") == 0) {
                    onProgress(95)
                    json.optJSONObject("data")?.optString("url")
                } else {
                    Log.e("UploadVideo", "Server error: " + json.optString("message"))
                    null
                }
            } else {
                Log.e("UploadVideo", "HTTP error: " + response.code)
                null
            }
        } catch (e: Exception) {
            Log.e("UploadVideo", "FAILED: " + e.message, e)
            null
        }
    }

    suspend fun uploadFile(file: java.io.File, mimeType: String): String? = withContext(Dispatchers.IO) {
        try {
            val requestBody = okhttp3.MultipartBody.Part.createFormData(
                "file", file.name,
                okhttp3.RequestBody.create(mimeType.toMediaType(), file)
            )
            val token = com.chuangpu.ai.util.PreferencesManager.getInstance(context).getToken() ?: ""
            val endpoint = if (mimeType.startsWith("image/")) "image" else "file"
            val uploadBaseUrl = "https://ai.xianbaba188.cn/upload-api/"
            val uploadClient = okhttp3.OkHttpClient.Builder()
                .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
                .readTimeout(60, java.util.concurrent.TimeUnit.SECONDS)
                .writeTimeout(60, java.util.concurrent.TimeUnit.SECONDS)
                .build()
            val request = okhttp3.Request.Builder()
                .url(uploadBaseUrl + endpoint)
                .addHeader("Authorization", "Bearer $token")
                .post(okhttp3.MultipartBody.Builder()
                    .setType(okhttp3.MultipartBody.FORM)
                    .addPart(requestBody)
                    .build())
                .build()
            val response = uploadClient.newCall(request).execute()
            if (response.isSuccessful) {
                val body = response.body?.string()
                val json = org.json.JSONObject(body ?: "")
                if (json.optInt("code") == 0) {
                    json.optJSONObject("data")?.optString("url")
                } else null
            } else null
        } catch (e: Exception) {
            null
        }
    }

    // V2.0.28: 创建支付订单
    suspend fun createPaymentOrder(planId: Int, payMethod: String = "native"): PaymentOrderResult? = withContext(Dispatchers.IO) {
        try {
            val token = com.chuangpu.ai.util.PreferencesManager.getInstance(context).getToken()
            val body = mapOf("plan_id" to planId, "pay_method" to payMethod)
            val request = Request.Builder()
                .url(baseUrl + "payment/create")
                .addHeader("Authorization", "Bearer $token")
                .post(gson.toJson(body).toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            if (responseBody != null) {
                val root = gson.fromJson(responseBody, Map::class.java) as? Map<*, *>
                if (root != null) {
                    val code = (root["code"] as? Number)?.toInt() ?: -1
                    val message = root["message"] as? String ?: ""
                    val dataMap = root["data"] as? Map<*, *>
                    PaymentOrderResult(code, message, dataMap)
                } else null
            } else null
        } catch (e: Exception) { null }
    }

    // V2.0.28: 查询订单状态
    suspend fun queryOrderStatus(orderNo: String): PaymentOrderResult? = withContext(Dispatchers.IO) {
        try {
            val token = com.chuangpu.ai.util.PreferencesManager.getInstance(context).getToken()
            val request = Request.Builder()
                .url(baseUrl + "payment/status/$orderNo")
                .addHeader("Authorization", "Bearer $token")
                .get()
                .build()
            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            if (responseBody != null) {
                val root = gson.fromJson(responseBody, Map::class.java) as? Map<*, *>
                if (root != null) {
                    val code = (root["code"] as? Number)?.toInt() ?: -1
                    val message = root["message"] as? String ?: ""
                    val dataMap = root["data"] as? Map<*, *>
                    PaymentOrderResult(code, message, dataMap)
                } else null
            } else null
        } catch (e: Exception) { null }
    }


    // V2.0.31: 修改密码
    suspend fun changePassword(oldPassword: String, newPassword: String): ApiResult<Any>? = withContext(Dispatchers.IO) {
        try {
            val token = com.chuangpu.ai.util.PreferencesManager.getInstance(context).getToken()
            val body = mapOf("old_password" to oldPassword, "new_password" to newPassword)
            val request = Request.Builder()
                .url(baseUrl + "auth/password")
                .addHeader("Authorization", "Bearer $token")
                .put(gson.toJson(body).toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            if (responseBody != null) {
                val root = gson.fromJson(responseBody, Map::class.java) as? Map<*, *>
                if (root != null) {
                    val code = (root["code"] as? Number)?.toInt() ?: -1
                    val message = root["message"] as? String ?: (root["detail"] as? String ?: "")
                    ApiResult<Any>(code, null, message)
                } else null
            } else null
        } catch (e: Exception) { null }
    }



    // V2.0.38: 测试激活VIP
    suspend fun activateTestVip(): PaymentOrderResult? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "vip/activate-test")
                .post("{}".toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            if (responseBody != null) {
                val root = gson.fromJson(responseBody, Map::class.java) as? Map<*, *>
                if (root != null) {
                    val code = (root["code"] as? Number)?.toInt() ?: -1
                    val message = root["message"] as? String ?: ""
                    val dataMap = root["data"] as? Map<*, *>
                    PaymentOrderResult(code, message, dataMap)
                } else null
            } else null
        } catch (e: Exception) { null }
    }

    // V2.0.38: 查询容器状态
    suspend fun getContainerStatus(): PaymentOrderResult? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "vip/status")
                .get()
                .build()
            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            if (responseBody != null) {
                val root = gson.fromJson(responseBody, Map::class.java) as? Map<*, *>
                if (root != null) {
                    val code = (root["code"] as? Number)?.toInt() ?: -1
                    val message = root["message"] as? String ?: ""
                    val dataMap = root["data"] as? Map<*, *>
                    PaymentOrderResult(code, message, dataMap)
                } else null
            } else null
        } catch (e: Exception) { null }
    }

    // V2.0.41: 创建容器（进聊天页时调用）
    suspend fun createContainer(): PaymentOrderResult? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "vip/create-container")
                .post("{}".toRequestBody("application/json".toMediaType()))
                .build()
            val response = client.newCall(request).execute()
            val responseBody = response.body?.string()
            if (responseBody != null) {
                val root = gson.fromJson(responseBody, Map::class.java) as? Map<*, *>
                if (root != null) {
                    val code = (root["code"] as? Number)?.toInt() ?: -1
                    val message = root["message"] as? String ?: ""
                    val dataMap = root["data"] as? Map<*, *>
                    PaymentOrderResult(code, message, dataMap)
                } else null
            } else null
        } catch (e: Exception) { null }
    }


    // 获取技能分类列表
    suspend fun getCategories(): List<String>? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url(baseUrl + "skill/categories/list")
                .get()
                .build()
            val response = client.newCall(request).execute()
            val body = response.body?.string()
            if (body != null) {
                val root = gson.fromJson(body, Map::class.java) as? Map<*, *>
                val code = (root?.get("code") as? Number)?.toInt() ?: -1
                if (code == 0) {
                    val data = root?.get("data") as? Map<*, *>
                    val cats = data?.get("categories") as? List<*>
                    cats?.mapNotNull { it as? String }
                } else null
            } else null
        } catch (e: Exception) { null }
    }

}
