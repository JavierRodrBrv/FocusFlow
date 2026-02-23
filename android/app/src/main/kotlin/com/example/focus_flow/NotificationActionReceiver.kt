package com.example.focus_flow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.focus_flow_notification.FocusFlowNotificationPlugin

class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        
        // Enviar la acción de vuelta al plugin local, que hablará con el MethodChannel en Dart
        FocusFlowNotificationPlugin.sendActionToDart(action)
    }
}
