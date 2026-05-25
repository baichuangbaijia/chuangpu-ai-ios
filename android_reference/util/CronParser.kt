package com.chuangpu.ai.util

object CronParser {
    
    private val weekDays = arrayOf("周日", "周一", "周二", "周三", "周四", "周五", "周六")
    
    fun parse(cron: String?): String {
        if (cron.isNullOrBlank()) return ""
        
        val parts = cron.trim().split(" ")
        if (parts.size < 5) return cron
        
        val minute = parts[0]
        val hour = parts[1]
        val dayOfMonth = parts[2]
        val month = parts[3]
        val dayOfWeek = parts[4]
        
        // 每天
        if (dayOfMonth == "*" && month == "*" && dayOfWeek == "*") {
            return "每天 ${pad(hour)}:${pad(minute)}"
        }
        
        // 每周
        if (dayOfMonth == "*" && month == "*" && dayOfWeek != "*") {
            val dayIndex = dayOfWeek.toIntOrNull() ?: return cron
            val day = weekDays.getOrElse(dayIndex) { "周$dayOfWeek" }
            return "$day ${pad(hour)}:${pad(minute)}"
        }
        
        // 每月
        if (dayOfMonth != "*" && month == "*" && dayOfWeek == "*") {
            return "每月${dayOfMonth}日 ${pad(hour)}:${pad(minute)}"
        }
        
        return cron
    }
    
    private fun pad(s: String): String {
        return if (s.length == 1) "0$s" else s
    }
}
