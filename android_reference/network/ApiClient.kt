package com.chuangpu.ai.network

import android.content.Context
import com.chuangpu.ai.util.PreferencesManager
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import okhttp3.*
import java.util.concurrent.TimeUnit

object ApiClient {
    private const val BASE_URL = "https://ai.xianbaba188.cn/agent/api/"
    private const val CONNECT_TIMEOUT = 30L
    private const val READ_TIMEOUT = 120L
    private const val WRITE_TIMEOUT = 30L

    private var client: OkHttpClient? = null
    private val gson = Gson()

    fun getClient(context: Context): OkHttpClient {
        if (client == null) {
            client = OkHttpClient.Builder()
                .connectTimeout(CONNECT_TIMEOUT, TimeUnit.SECONDS)
                .readTimeout(READ_TIMEOUT, TimeUnit.SECONDS)
                .writeTimeout(WRITE_TIMEOUT, TimeUnit.SECONDS)
                .addInterceptor { chain ->
                    val prefs = PreferencesManager.getInstance(context)
                    val token = prefs.getToken()
                    val request = chain.request().newBuilder()
                        .addHeader("Content-Type", "application/json")
                        .addHeader("Accept", "application/json")
                        .apply {
                            if (!token.isNullOrEmpty()) {
                                addHeader("Authorization", "Bearer $token")
                            }
                        }
                        .build()
                    chain.proceed(request)
                }
                .build()
        }
        return client!!
    }

    fun getSseClient(context: Context): OkHttpClient {
        return OkHttpClient.Builder()
            .connectTimeout(CONNECT_TIMEOUT, TimeUnit.SECONDS)
            .readTimeout(120, TimeUnit.SECONDS)
            .writeTimeout(WRITE_TIMEOUT, TimeUnit.SECONDS)
            .addInterceptor { chain ->
                val prefs = PreferencesManager.getInstance(context)
                val token = prefs.getToken()
                val request = chain.request().newBuilder()
                    .addHeader("Content-Type", "application/json")
                    .addHeader("Accept", "text/event-stream")
                    .apply {
                        if (!token.isNullOrEmpty()) {
                            addHeader("Authorization", "Bearer $token")
                        }
                    }
                    .build()
                chain.proceed(request)
            }
            .build()
    }

    fun <T> parseResponse(response: Response, type: java.lang.reflect.Type): T? {
        return try {
            val body = response.body?.string()
            if (body != null) {
                gson.fromJson<T>(body, type)
            } else null
        } catch (e: Exception) {
            null
        }
    }

    fun <T> parseResponse(response: Response, clazz: Class<T>): T? {
        return try {
            val body = response.body?.string()
            if (body != null) {
                gson.fromJson(body, clazz)
            } else null
        } catch (e: Exception) {
            null
        }
    }
}

data class ApiResult<T>(
    val code: Int = 0,
    val data: T? = null,
    val message: String? = null
)

data class ApiListResult<T>(
    val code: Int = 0,
    val data: ListData<T>? = null,
    val message: String? = null
)

data class ListData<T>(
    val list: List<T>? = null,
    val total: Int = 0,
    val page: Int = 1,
    val limit: Int = 20
)
