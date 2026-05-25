package com.chuangpu.ai.util

import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.chuangpu.ai.R

object ThemeHelper {
    
    data class ThemeColors(
        val bgDark: Int,
        val bgCard: Int,
        val primaryPurple: Int,
        val secondaryBlue: Int,
        val accentOrange: Int,
        val gradientStart: Int,
        val gradientEnd: Int,
        val tabBarBg: Int,
        val dividerColor: Int,
        val textGray: Int
    )
    
    val themes = mapOf(
        "default" to ThemeColors(
            0xFF0A0A0F.toInt(), 0xFF1A1A2E.toInt(), 0xFF7C3AED.toInt(),
            0xFF3B82F6.toInt(), 0xFFF97316.toInt(), 0xFF7C3AED.toInt(), 0xFF3B82F6.toInt(),
            0xD90A0A0F.toInt(), 0x1AFFFFFF.toInt(), 0xFF9CA3AF.toInt()
        ),
        "deep-space" to ThemeColors(
            0xFF121220.toInt(), 0xFF1C1C3A.toInt(), 0xFF6366F1.toInt(),
            0xFF4F8FF7.toInt(), 0xFFFB923C.toInt(), 0xFF6366F1.toInt(), 0xFF4F8FF7.toInt(),
            0xD9121220.toInt(), 0x1AFFFFFF.toInt(), 0xFF9CA3AF.toInt()
        ),
        "dark-blue" to ThemeColors(
            0xFF0B1622.toInt(), 0xFF132F4C.toInt(), 0xFF1976D2.toInt(),
            0xFF42A5F5.toInt(), 0xFFFF9800.toInt(), 0xFF1976D2.toInt(), 0xFF42A5F5.toInt(),
            0xD90B1622.toInt(), 0x1AFFFFFF.toInt(), 0xFF9CA3AF.toInt()
        ),
        "star-purple" to ThemeColors(
            0xFF1A0A2E.toInt(), 0xFF2D1B4E.toInt(), 0xFFA855F7.toInt(),
            0xFF818CF8.toInt(), 0xFFF472B6.toInt(), 0xFFA855F7.toInt(), 0xFF818CF8.toInt(),
            0xD91A0A2E.toInt(), 0x1AFFFFFF.toInt(), 0xFF9CA3AF.toInt()
        )
    )
    
    fun getCurrentColors(prefs: PreferencesManager): ThemeColors {
        val themeId = prefs.getTheme()
        return themes[themeId] ?: themes["default"]!!
    }
    
    /**
     * 通用：改根背景+状态栏+递归遍历标记了tag的子View
     * XML里用 android:tag="theme:card" / "theme:primary" / "theme:gradient" 等标记
     */
    fun applyToActivity(activity: AppCompatActivity) {
        val prefs = PreferencesManager.getInstance(activity)
        val colors = getCurrentColors(prefs)
        
        // 状态栏颜色
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            activity.window.statusBarColor = colors.bgCard
        }
        
        // 根布局背景
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content) ?: return
        val root = contentView.getChildAt(0) as? ViewGroup ?: return
        root.setBackgroundColor(colors.bgDark)
        
        // 递归处理带tag的子View
        applyTaggedViews(root, colors)
    }
    
    /**
     * 给Fragment的根View应用主题
     */
    fun applyToView(root: View, prefs: PreferencesManager) {
        val colors = getCurrentColors(prefs)
        root.setBackgroundColor(colors.bgDark)
        if (root is ViewGroup) applyTaggedViews(root, colors)
    }
    
    /**
     * 递归遍历所有子View，根据tag应用主题色
     */
    private fun applyTaggedViews(viewGroup: ViewGroup, colors: ThemeColors) {
        for (i in 0 until viewGroup.childCount) {
            val child = viewGroup.getChildAt(i)
            val tag = child.tag as? String
            
            when (tag) {
                "theme:card" -> {
                    val bg = GradientDrawable().apply {
                        setColor(colors.bgCard)
                        cornerRadius = 12f * child.resources.displayMetrics.density
                    }
                    child.background = bg
                }
                "theme:card_alpha" -> {
                    val bg = GradientDrawable().apply {
                        setColor((0xCC000000L or (colors.bgCard.toLong() and 0xFFFFFF)).toInt())
                        cornerRadius = 12f * child.resources.displayMetrics.density
                    }
                    child.background = bg
                }
                "theme:primary" -> {
                    if (child is TextView) child.setTextColor(colors.primaryPurple)
                    if (child is ImageView) child.setColorFilter(colors.primaryPurple)
                }
                "theme:gradient" -> {
                    val bg = GradientDrawable(
                        GradientDrawable.Orientation.LEFT_RIGHT,
                        intArrayOf(colors.gradientStart, colors.gradientEnd)
                    ).apply { cornerRadius = 12f * child.resources.displayMetrics.density }
                    child.background = bg
                }
                "theme:gradient_alpha" -> {
                    val bg = GradientDrawable(
                        GradientDrawable.Orientation.LEFT_RIGHT,
                        intArrayOf(
                            (0x4D000000L or (colors.gradientStart.toLong() and 0xFFFFFF)).toInt(),
                            (0x4D000000L or (colors.gradientEnd.toLong() and 0xFFFFFF)).toInt()
                        )
                    ).apply { cornerRadius = 12f * child.resources.displayMetrics.density }
                    child.background = bg
                }
                "theme:gradient_oval" -> {
                    val bg = GradientDrawable(
                        GradientDrawable.Orientation.LEFT_RIGHT,
                        intArrayOf(colors.gradientStart, colors.gradientEnd)
                    ).apply { shape = GradientDrawable.OVAL }
                    child.background = bg
                }
                "theme:header" -> {
                    child.setBackgroundColor(colors.bgCard)
                }
                "theme:tabbar" -> {
                    val bg = GradientDrawable().apply {
                        setColor(colors.tabBarBg)
                        cornerRadius = 0f
                    }
                    child.background = bg
                }
                "theme:divider" -> {
                    child.setBackgroundColor(colors.dividerColor)
                }
                "theme:input_bg" -> {
                    val bg = GradientDrawable().apply {
                        setColor(0x0DFFFFFF)  // 半透明白，通用
                        cornerRadius = 20f * child.resources.displayMetrics.density
                    }
                    child.background = bg
                }
            }
            
            // 递归子View
            if (child is ViewGroup) {
                applyTaggedViews(child, colors)
            }
        }
    }
    
    /**
     * 创建渐变drawable
     */
    fun createGradientDrawable(colors: ThemeColors, cornerRadius: Float = 0f): GradientDrawable {
        return GradientDrawable(
            GradientDrawable.Orientation.LEFT_RIGHT,
            intArrayOf(colors.gradientStart, colors.gradientEnd)
        ).apply {
            if (cornerRadius > 0) this.cornerRadius = cornerRadius
        }
    }
}
