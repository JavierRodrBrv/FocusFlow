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

class FocusFlowNotificationPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    companion object {
        private var instance: FocusFlowNotificationPlugin? = null
        
        fun sendActionToDart(action: String) {
            instance?.channel?.invokeMethod("onNotificationAction", action)
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        instance = this
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.focus_flow/notification")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "updateNotification" -> {
                val time = call.argument<String>("time") ?: "00:00"
                val status = call.argument<String>("status") ?: "running"
                updateCustomNotification(time, status)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun updateCustomNotification(time: String, status: String) {
        val notificationId = 888 
        val channelId = "focus_flow_channel"

        // Usamos el nombre del paquete del host para encontrar los recursos
        val hostPackageName = context.packageName
        val layoutId = context.resources.getIdentifier("custom_pomodoro_notification", "layout", hostPackageName)
        
        if (layoutId == 0) {
            println("[FocusFlowNotification] Layout NOT FOUND")
            return
        }

        val remoteViews = RemoteViews(hostPackageName, layoutId)
        
        val tvTimeId = context.resources.getIdentifier("tv_time", "id", hostPackageName)
        remoteViews.setTextViewText(tvTimeId, time)

        val btnActionId = context.resources.getIdentifier("btn_action", "id", hostPackageName)

        if (status == "initial") {
            remoteViews.setViewVisibility(btnActionId, android.view.View.GONE)
            // Color normal y tamaño normal para el mensaje de espera
            remoteViews.setTextColor(tvTimeId, android.graphics.Color.parseColor("#FFFFFF"))
            remoteViews.setTextViewTextSize(tvTimeId, android.util.TypedValue.COMPLEX_UNIT_SP, 16f)
        } else {
            remoteViews.setViewVisibility(btnActionId, android.view.View.VISIBLE)
            // Color rojo y tamaño grande para el contador
            remoteViews.setTextColor(tvTimeId, android.graphics.Color.parseColor("#FF5252"))
            remoteViews.setTextViewTextSize(tvTimeId, android.util.TypedValue.COMPLEX_UNIT_SP, 38f)
            
            val icPauseId = context.resources.getIdentifier("ic_pause", "drawable", hostPackageName)
            val icPlayId = context.resources.getIdentifier("ic_play", "drawable", hostPackageName)
            
            // Acción del botón
            val actionIntent = if (status == "running" || status == "resting") {
                remoteViews.setImageViewResource(btnActionId, icPauseId)
                Intent("PAUSE_ACTION")
            } else {
                remoteViews.setImageViewResource(btnActionId, icPlayId)
                Intent("PLAY_ACTION")
            }

            // Para que funcione con un Receiver local
            actionIntent.setPackage(hostPackageName)

            // Forzar color blanco para que se vea bien en fondo oscuro
            remoteViews.setInt(btnActionId, "setColorFilter", android.graphics.Color.WHITE)

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                actionIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            remoteViews.setOnClickPendingIntent(btnActionId, pendingIntent)
        }

        // Intent para abrir la app al pulsar la notificación
        val mainIntent = context.packageManager.getLaunchIntentForPackage(hostPackageName)
        val mainPendingIntent = PendingIntent.getActivity(
            context,
            0,
            mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val launcherIconId = context.resources.getIdentifier("launcher_icon", "mipmap", hostPackageName)

        val notificationBuilder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(launcherIconId)
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setOngoing(status == "running" || status == "resting")
            .setOnlyAlertOnce(true)
            .setContentIntent(mainPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, notificationBuilder.build())
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (instance == this) {
            instance = null
        }
        channel.setMethodCallHandler(null)
    }
}
