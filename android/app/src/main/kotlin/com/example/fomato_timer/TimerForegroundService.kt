package com.example.fomato_timer

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.*
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * 타이머 포그라운드 서비스
 * 
 * 백그라운드에서도 안정적으로 타이머가 동작하도록 하는 포그라운드 서비스입니다.
 * 매 초마다 알림을 업데이트하여 실시간 타이머 정보를 제공합니다.
 */
class TimerForegroundService : Service() {
    
    companion object {
        const val CHANNEL_ID = "timer_foreground_service"
        const val COMPLETION_CHANNEL_ID = "timer_completion"
        const val NOTIFICATION_ID = 1001
        
        // 서비스 액션
        const val ACTION_START_TIMER = "START_TIMER"
        const val ACTION_PAUSE_TIMER = "PAUSE_TIMER"
        const val ACTION_RESUME_TIMER = "RESUME_TIMER"
        const val ACTION_STOP_TIMER = "STOP_TIMER"
        
        // 인텐트 엑스트라
        const val EXTRA_DURATION = "duration"
        const val EXTRA_FARM_NAME = "farm_name"
        const val EXTRA_MODE = "mode"
        
        private var isServiceRunning = false
        
        fun isRunning(): Boolean = isServiceRunning
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private var startTime: Long = 0
    private var totalDurationSeconds: Int = 0
    private var isPaused: Boolean = false
    private var pausedTime: Long = 0
    private var farmName: String = "집중시간"
    private var mode: String = "focus"
    
    private var updateRunnable: Runnable? = null
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        isServiceRunning = true
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_TIMER -> {
                startTimer(
                    intent.getIntExtra(EXTRA_DURATION, 1500),
                    intent.getStringExtra(EXTRA_FARM_NAME) ?: "집중시간",
                    intent.getStringExtra(EXTRA_MODE) ?: "focus"
                )
            }
            ACTION_PAUSE_TIMER -> {
                val remainingSeconds = intent.getIntExtra("remainingSeconds", 0)
                pauseTimer(remainingSeconds)
            }
            ACTION_RESUME_TIMER -> {
                val remainingSeconds = intent.getIntExtra("remainingSeconds", 0)
                resumeTimer(remainingSeconds)
            }
            ACTION_STOP_TIMER -> stopTimer()
        }
        
        return START_STICKY // 서비스가 종료되면 시스템이 자동으로 재시작
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        stopUpdateRunnable()
        isServiceRunning = false
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // 타이머 진행 알림 채널 (조용함)
            val timerChannel = NotificationChannel(
                CHANNEL_ID,
                "타이머 진행",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "뽀모도로 타이머 진행 상황을 표시합니다"
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            }
            
            // 완료 알림 채널 (높은 우선순위)
            val completionChannel = NotificationChannel(
                COMPLETION_CHANNEL_ID,
                "타이머 완료",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "뽀모도로 타이머 완료 알림을 표시합니다"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            
            notificationManager.createNotificationChannel(timerChannel)
            notificationManager.createNotificationChannel(completionChannel)
        }
    }
    
    private fun startTimer(duration: Int, farmName: String, mode: String) {
        this.totalDurationSeconds = duration
        this.farmName = farmName
        this.mode = mode
        this.startTime = System.currentTimeMillis()
        this.isPaused = false
        this.pausedTime = 0
        
        startUpdateRunnable()
        showNotification(duration)
    }
    
    private fun pauseTimer(flutterRemainingSeconds: Int = 0) {
        isPaused = true
        pausedTime = System.currentTimeMillis()
        
        // Flutter에서 전달받은 남은 시간이 있으면 사용 (동기화)
        if (flutterRemainingSeconds > 0) {
            // Flutter의 정확한 남은 시간으로 덮어쓰기
            totalDurationSeconds = flutterRemainingSeconds
            startTime = System.currentTimeMillis()  // 새로운 기준점 설정
        }
        
        stopUpdateRunnable()
    }
    
    private fun resumeTimer(flutterRemainingSeconds: Int = 0) {
        if (isPaused) {
            // Flutter에서 전달받은 남은 시간이 있으면 사용 (동기화)
            if (flutterRemainingSeconds > 0) {
                // Flutter의 정확한 남은 시간으로 새로 시작
                totalDurationSeconds = flutterRemainingSeconds
                startTime = System.currentTimeMillis()
            } else {
                // 기존 방식: 일시정지 시간만큼 조정
                val pauseDuration = System.currentTimeMillis() - pausedTime
                startTime += pauseDuration
            }
            
            isPaused = false
            startUpdateRunnable()
        }
    }
    
    private fun stopTimer() {
        stopUpdateRunnable()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }
    
    private fun startUpdateRunnable() {
        stopUpdateRunnable()
        updateRunnable = object : Runnable {
            override fun run() {
                if (!isPaused) {
                    val elapsedSeconds = (System.currentTimeMillis() - startTime) / 1000
                    val remainingSeconds = (totalDurationSeconds - elapsedSeconds).toInt()
                    
                    if (remainingSeconds <= 0) {
                        // 타이머 완료
                        showCompletionNotification()
                        // 완료 알림 표시 후 약간의 지연을 두고 서비스 중지
                        handler.postDelayed({
                            stopSelf()
                        }, 1000)
                    } else {
                        updateNotification(remainingSeconds)
                        handler.postDelayed(this, 1000)
                    }
                }
            }
        }
        handler.post(updateRunnable!!)
    }
    
    private fun stopUpdateRunnable() {
        updateRunnable?.let {
            handler.removeCallbacks(it)
            updateRunnable = null
        }
    }
    
    private fun showNotification(remainingSeconds: Int) {
        val minutes = remainingSeconds / 60
        val seconds = remainingSeconds % 60
        val timeText = String.format("%02d:%02d", minutes, seconds)
        
        val emoji = when (mode) {
            "focus" -> "🍅"
            "shortBreak" -> "😌"
            "longBreak" -> "😴"
            else -> "⏱️"
        }
        
        val modeText = when (mode) {
            "focus" -> "집중 시간"
            "shortBreak" -> "짧은 휴식"
            "longBreak" -> "긴 휴식"
            else -> "타이머"
        }
        
        val title = if (mode == "focus" && farmName.isNotEmpty() && farmName != "집중시간") {
            "$emoji $modeText - $farmName"
        } else {
            "$emoji $modeText"
        }
        
        // 메인 액티비티로 이동하는 인텐트
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, mainIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 일시정지/재개 버튼 인텐트
        val pauseResumeAction = if (isPaused) {
            val resumeIntent = Intent(this, TimerForegroundService::class.java).apply {
                action = ACTION_RESUME_TIMER
            }
            val resumePendingIntent = PendingIntent.getService(
                this, 1, resumeIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            NotificationCompat.Action(0, "재개", resumePendingIntent)
        } else {
            val pauseIntent = Intent(this, TimerForegroundService::class.java).apply {
                action = ACTION_PAUSE_TIMER
            }
            val pausePendingIntent = PendingIntent.getService(
                this, 2, pauseIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            NotificationCompat.Action(0, "일시정지", pausePendingIntent)
        }
        
        // 정지 버튼 인텐트
        val stopIntent = Intent(this, TimerForegroundService::class.java).apply {
            action = ACTION_STOP_TIMER
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 3, stopIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val stopAction = NotificationCompat.Action(0, "정지", stopPendingIntent)
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(if (isPaused) "$timeText (일시정지됨)" else timeText)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(pauseResumeAction)
            .addAction(stopAction)
            .setPriority(NotificationCompat.PRIORITY_LOW) // 진행 중에는 낮은 우선순위
            .setDefaults(0) // 소리, 진동 없음
            .setColor(0xFF4CAF50.toInt()) // 앱의 Primary 컬러
            .build()
        
        startForeground(NOTIFICATION_ID, notification)
    }
    
    private fun updateNotification(remainingSeconds: Int) {
        showNotification(remainingSeconds)
    }
    
    private fun showCompletionNotification() {
        val emoji = if (mode == "focus") "🎉" else "⏰"
        val title = if (mode == "focus") {
            "$emoji 집중 완료!"
        } else {
            "$emoji 휴식 완료!"
        }
        val message = if (mode == "focus") {
            if (farmName.isNotEmpty() && farmName != "집중시간") {
                "${farmName}에서 토마토를 수확했습니다! 🍅"
            } else {
                "토마토를 수확했습니다! 🍅"
            }
        } else {
            "휴식이 끝났습니다. 이제 집중 시간입니다!"
        }
        
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, mainIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 포그라운드 서비스 중지 (완료 시에는 더 이상 포그라운드 서비스 불필요)
        stopForeground(STOP_FOREGROUND_REMOVE)
        
        val notification = NotificationCompat.Builder(this, COMPLETION_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(false) // 완료 시에는 지속적이지 않음
            .setColor(0xFF4CAF50.toInt())
            .build()
        
        // 완료 알림을 새로운 ID로 표시 (포그라운드 서비스와 분리)
        val notificationManager = NotificationManagerCompat.from(this)
        try {
            notificationManager.notify(NOTIFICATION_ID + 100, notification)
        } catch (e: SecurityException) {
            // 알림 권한이 없는 경우 무시
        }
    }
}