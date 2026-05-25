package com.chuangpu.ai.ui.chat

import android.os.Bundle
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity
import com.bumptech.glide.Glide
import com.chuangpu.ai.R

class FullscreenImageActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_fullscreen_image)

        val imageUrl = intent.getStringExtra("image_url") ?: run { finish(); return }
        val ivFullscreen = findViewById<ImageView>(R.id.ivFullscreen)
        val ivClose = findViewById<ImageView>(R.id.ivClose)

        if (imageUrl.startsWith("content://") || imageUrl.startsWith("file://")) {
            ivFullscreen.setImageURI(android.net.Uri.parse(imageUrl))
        } else {
            Glide.with(this).load(imageUrl).into(ivFullscreen)
        }

        ivClose.setOnClickListener { finish() }
        ivFullscreen.setOnClickListener { finish() }
    }

    override fun onBackPressed() {
        finish()
    }
}
