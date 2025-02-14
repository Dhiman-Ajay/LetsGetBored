package com.example.digital_wellbeing_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val SCREEN_STATE_CHANNEL = "screen_state_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_STATE_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val intent = Intent(this@MainActivity, ScreenStateService::class.java)
                    startService(intent)  // Start service to monitor screen state
                }

                override fun onCancel(arguments: Any?) {
                    val intent = Intent(this@MainActivity, ScreenStateService::class.java)
                    stopService(intent)  // Stop service
                }
            }
        )
    }
}
