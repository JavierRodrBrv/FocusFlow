package com.example.focus_flow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.focus_flow_notification.FocusFlowNotificationPlugin

class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        
        // Simplemente enviar la acción de vuelta al plugin, que hablará con el MethodChannel
        FocusFlowNotificationPlugin.sendActionToDart(action)
    }
}
