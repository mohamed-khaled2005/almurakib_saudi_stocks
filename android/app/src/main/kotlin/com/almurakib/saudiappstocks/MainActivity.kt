package com.almurakib.saudiappstocks

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createDefaultNotificationChannel()
    }

    private fun createDefaultNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val channel = NotificationChannel(
            "default_channel",
            "General Notifications",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "General app notifications"
            enableVibration(true)
        }

        manager.createNotificationChannel(channel)
    }
}
