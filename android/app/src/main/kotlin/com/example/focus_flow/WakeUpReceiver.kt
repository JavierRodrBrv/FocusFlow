package com.example.focus_flow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

class WakeUpReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("WakeUpReceiver", "Recibida señal para despertar pantalla")
        
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        
        // Usamos las banderas clásicas de Alarma.
        // SCREEN_BRIGHT_WAKE_LOCK: Asegura que la pantalla se ilumine.
        // ACQUIRE_CAUSES_WAKEUP: Fuerza el encendido inmediato.
        // ON_AFTER_RELEASE: Mantiene la pantalla encendida un poco más después de soltar el lock.
        @Suppress("DEPRECATION")
        val wakeLock = powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "FocusFlow:AlarmWakeUp"
        )

        // Adquirimos el bloqueo por 3 segundos para garantizar que el sistema procese la notificación
        // y la muestre en la pantalla recién encendida.
        wakeLock.acquire(3000)
        Log.d("WakeUpReceiver", "WakeLock adquirido")
    }
}