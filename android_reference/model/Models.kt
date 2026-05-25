package com.chuangpu.ai.model

data class User(
    val id: Long = 0,
    val name: String = "",
    val nickname: String? = null,
    val phone: String? = null,
    val avatar: String? = null,
    val vip_level: String? = null
)

data class LoginData(
    val token: String = "",
    val refresh_token: String? = null,
    val user_id: Long = 0,
    val expires_in: Int = 0,
    val user: User? = null
)

data class Conversation(
    val id: Long = 0,
    val title: String = "",
    val session_id: String = "",
    val model: String = "",
    val updated_at: String? = null,
    val created_at: String? = null,
    val user_id: Long = 0,
    val messageCount: Int = 0
)

data class Message(
    val role: String = "",
    var content: String = "",
    val text: String? = null,
    val fileCards: List<FileCard>? = null,
    var imageUrl: String? = null,
    var videoUrl: String? = null,
    var thumbnailUrl: String? = null,
    var localVideoUri: String? = null  // 本地URI，用于缩略图提取
)

data class FileCard(
    val url: String = "",
    val filename: String = "",
    val type: String = "",
    val size: String = "",
    val icon: String = ""
)

data class MessageResponse(
    val content: String = "",
    val session_id: String? = null
)

data class Skill(
    val id: String = "",
    val name: String = "",
    val description: String = "",
    val category: String? = null,
    val slug: String? = null,
    val version: String? = null,
    val downloads: Int = 0,
    val is_installed: Boolean = false,
    val popular: Boolean = false
)

data class Memory(
    val id: String = "",
    val content: String = "",
    val created_at: String? = null
)

data class MemoryListData(
    val list: List<Memory> = emptyList(),
    val total: Int = 0
)

data class Task(
    val id: String = "",
    val name: String = "",
    val prompt: String = "",
    val cron_expression: String = "",
    val status: String = "active",
    val notification_enabled: Boolean = true,
    val description: String? = null,
    val run_count: Int = 0,
    val next_run: String? = null
)

data class TaskListData(
    val list: List<Task> = emptyList()
)

data class CreditData(
    val credits: Int = 0,
    val vip_level: String = "free",
    val vip_expire: String? = null
)

data class Subtask(
    val id: String = "",
    val name: String = "",
    val status: String = "running",
    val created_at: String? = null
)

data class InstalledData(
    val total: Int = 0,
    val list: List<Skill> = emptyList()
)

data class MySkillsData(
    val learned: List<String> = emptyList(),
    val installed: List<Skill> = emptyList()
)

data class HistoryMessage(
    val role: String? = null,
    val content: String? = null
)

data class HistoryListData(
    val list: List<HistoryMessage> = emptyList()
)


// V2.0.28: 支付订单结果
data class PaymentOrderResult(
    val code: Int,
    val message: String,
    val data: Map<*, *>?
) {
    val order_no: String? get() = data?.get("order_no") as? String
    val code_url: String? get() = data?.get("code_url") as? String
    val amount: Int? get() = (data?.get("amount") as? Number)?.toInt()
    val status: String? get() = data?.get("status") as? String
}
