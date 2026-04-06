package com.example.focus_flow_notification

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.graphics.Color
import android.util.TypedValue
import android.content.res.Configuration

import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.os.Build

class FocusFlowNotificationPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action
            if (action == "PAUSE_ACTION" || action == "PLAY_ACTION" || action == "NEXT_ACTION") {
                sendActionToDart(action)
            }
        }
    }

    companion object {
        private var instance: FocusFlowNotificationPlugin? = null
        private var lastActionTime: Long = 0
        
        fun sendActionToDart(action: String) {
            val now = System.currentTimeMillis()
            if (now - lastActionTime < 500) return // debounce to fix double trigger
            lastActionTime = now
            instance?.channel?.invokeMethod("onNotificationAction", action)
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        instance = this
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.focus_flow/notification")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        val filter = IntentFilter().apply {
            addAction("PAUSE_ACTION")
            addAction("PLAY_ACTION")
            addAction("NEXT_ACTION")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "updateNotification" -> {
                val time = call.argument<String>("time") ?: "00:00"
                val status = call.argument<String>("status") ?: "running"
                val phase = call.argument<String>("phase") ?: "focus"
                updateCustomNotification(time, status, phase)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun isDarkMode(): Boolean {
        return (context.resources.configuration.uiMode and 
                Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    }

    private fun updateCustomNotification(time: String, status: String, phase: String) {
        val notificationId = 888 
        val channelId = "focus_flow_channel"
        val hostPackageName = context.packageName

        val layoutId = context.resources.getIdentifier("custom_pomodoro_notification", "layout", hostPackageName)
        if (layoutId == 0) return

        val remoteViews = RemoteViews(hostPackageName, layoutId)
        val tvTimeId = context.resources.getIdentifier("tv_time", "id", hostPackageName)
        val btnActionId = context.resources.getIdentifier("btn_action", "id", hostPackageName)
        val btnNextId = context.resources.getIdentifier("btn_next", "id", hostPackageName)

        val tvStatusId = context.resources.getIdentifier("tv_status", "id", hostPackageName)

        val darkMode = isDarkMode()
        val adaptiveColor = if (darkMode) Color.WHITE else Color.BLACK

        // 1. Set the Text
        remoteViews.setTextViewText(tvTimeId, time)
        
        val displayStatus = when (phase) {
            "waiting" -> "Preparación"
            "break" -> "Descanso"
            else -> "Enfoque"
        }
        remoteViews.setTextViewText(tvStatusId, displayStatus)

        // 2. Logic for visibility, colors and sizes based on status
        if (status == "initial" || status == "finished") {
            remoteViews.setViewVisibility(btnActionId, android.view.View.GONE)
            remoteViews.setViewVisibility(btnNextId, android.view.View.GONE)
            remoteViews.setTextColor(tvTimeId, adaptiveColor)
            remoteViews.setTextViewTextSize(tvTimeId, TypedValue.COMPLEX_UNIT_SP, 16f)
        } else {
            remoteViews.setViewVisibility(btnActionId, android.view.View.VISIBLE)
            remoteViews.setViewVisibility(btnNextId, android.view.View.VISIBLE)
            
            // Text color logic: Red if running/resting, Adaptive if paused
            if (status == "running" || status == "resting") {
                remoteViews.setTextColor(tvTimeId, Color.parseColor("#FF5252"))
                remoteViews.setTextColor(tvStatusId, Color.parseColor("#FF8A80"))
            } else {
                remoteViews.setTextColor(tvTimeId, adaptiveColor)
                remoteViews.setTextColor(tvStatusId, if (darkMode) Color.LTGRAY else Color.DKGRAY)
            }
            
            // Adjust text size based on sub-state
            val isBreakState = phase == "break"
            val textSize = if (isBreakState) 26f else 28f
            remoteViews.setTextViewTextSize(tvTimeId, TypedValue.COMPLEX_UNIT_SP, textSize)
            
            val icPauseId = context.resources.getIdentifier("ic_pause", "drawable", hostPackageName)
            val icPlayId = context.resources.getIdentifier("ic_play", "drawable", hostPackageName)
            
            val actionIntent = if (status == "running" || status == "resting") {
                remoteViews.setImageViewResource(btnActionId, icPauseId)
                Intent("PAUSE_ACTION")
            } else {
                remoteViews.setImageViewResource(btnActionId, icPlayId)
                Intent("PLAY_ACTION")
            }
            actionIntent.setPackage(hostPackageName)
            
            // Adaptive button tint
            remoteViews.setInt(btnActionId, "setColorFilter", adaptiveColor)
            remoteViews.setInt(btnNextId, "setColorFilter", adaptiveColor)

            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, actionIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            remoteViews.setOnClickPendingIntent(btnActionId, pendingIntent)

            // Setup Next Button
            val nextIntent = Intent("NEXT_ACTION")
            nextIntent.setPackage(hostPackageName)
            val nextPendingIntent = PendingIntent.getBroadcast(
                context, 1, nextIntent, // Different request code!
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            remoteViews.setOnClickPendingIntent(btnNextId, nextPendingIntent)
        }

        // 3. App Launch Intent
        val mainIntent = context.packageManager.getLaunchIntentForPackage(hostPackageName)
        val mainPendingIntent = PendingIntent.getActivity(
            context, 0, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 4. Build Notification
        val launcherIconId = context.resources.getIdentifier("launcher_icon", "mipmap", hostPackageName)

        val notificationBuilder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(launcherIconId)
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setOngoing(status == "running" || status == "resting")
            .setOnlyAlertOnce(true)
            .setContentIntent(mainPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, notificationBuilder.build())
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (instance == this) instance = null
        channel.setMethodCallHandler(null)
        try {
            context.unregisterReceiver(receiver)
        } catch (e: Exception) {
            // Ignore if already unregistered
        }
    }
}
