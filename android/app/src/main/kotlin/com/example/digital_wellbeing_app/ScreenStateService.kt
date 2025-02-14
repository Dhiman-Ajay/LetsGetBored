package com.example.digital_wellbeing_app

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log

class ScreenStateService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val screenOn = intent?.getBooleanExtra("screen_on", false) ?: false
        Log.d("ScreenStateService", "Screen on: $screenOn")
        // Implement your logic here, e.g., send data back to Flutter through a different method
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("ScreenStateService", "Service destroyed")
    }
}
