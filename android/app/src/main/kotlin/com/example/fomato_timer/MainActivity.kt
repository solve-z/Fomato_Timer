package com.example.fomato_timer

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.fomato_timer/timer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundTimer" -> {
                    val duration = call.argument<Int>("duration") ?: 1500
                    val farmName = call.argument<String>("farmName") ?: "집중시간"
                    val mode = call.argument<String>("mode") ?: "focus"
                    
                    startForegroundTimer(duration, farmName, mode)
                    result.success("Timer started")
                }
                "pauseForegroundTimer" -> {
                    val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0
                    pauseForegroundTimer(remainingSeconds)
                    result.success("Timer paused")
                }
                "resumeForegroundTimer" -> {
                    val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0
                    resumeForegroundTimer(remainingSeconds)
                    result.success("Timer resumed")
                }
                "stopForegroundTimer" -> {
                    stopForegroundTimer()
                    result.success("Timer stopped")
                }
                "isForegroundTimerRunning" -> {
                    result.success(TimerForegroundService.isRunning())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun startForegroundTimer(duration: Int, farmName: String, mode: String) {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_START_TIMER
            putExtra(TimerForegroundService.EXTRA_DURATION, duration)
            putExtra(TimerForegroundService.EXTRA_FARM_NAME, farmName)
            putExtra(TimerForegroundService.EXTRA_MODE, mode)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
    
    private fun pauseForegroundTimer(remainingSeconds: Int) {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_PAUSE_TIMER
            putExtra("remainingSeconds", remainingSeconds)
        }
        startService(intent)
    }
    
    private fun resumeForegroundTimer(remainingSeconds: Int) {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_RESUME_TIMER
            putExtra("remainingSeconds", remainingSeconds)
        }
        startService(intent)
    }
    
    private fun stopForegroundTimer() {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_STOP_TIMER
        }
        startService(intent)
    }
}
