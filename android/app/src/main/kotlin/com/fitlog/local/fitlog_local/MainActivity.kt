package com.fitlog.local.fitlog_local

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.FlutterInjector
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingOpenActiveWorkoutDraft = false
    private var pendingNotificationPayload: WorkoutNotificationPayload? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WORKOUT_NOTIFICATION_CHANNEL,
        )
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeInitialOpenRequest" -> {
                    val shouldOpen = pendingOpenActiveWorkoutDraft
                    pendingOpenActiveWorkoutDraft = false
                    result.success(shouldOpen)
                }
                "showOrUpdateWorkoutNotification" -> {
                    val payload = WorkoutNotificationPayload.from(call.arguments)
                    if (payload == null) {
                        result.error(
                            "invalid_notification_payload",
                            "Workout notification payload is missing required fields.",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    showOrRequestPermission(payload)
                    result.success(null)
                }
                "cancelWorkoutNotification" -> {
                    cancelWorkoutNotification()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        pendingOpenActiveWorkoutDraft = shouldOpenActiveWorkoutDraft(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (shouldOpenActiveWorkoutDraft(intent)) {
            pendingOpenActiveWorkoutDraft = true
            channel?.invokeMethod("openActiveWorkoutDraft", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_NOTIFICATION_PERMISSION) {
            return
        }
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        val payload = pendingNotificationPayload
        pendingNotificationPayload = null
        if (granted && payload != null) {
            postWorkoutNotification(payload)
        }
    }

    private fun shouldOpenActiveWorkoutDraft(intent: Intent?): Boolean {
        return intent?.getBooleanExtra(EXTRA_OPEN_ACTIVE_WORKOUT_DRAFT, false) == true
    }

    private fun showOrRequestPermission(payload: WorkoutNotificationPayload) {
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            pendingNotificationPayload = payload
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_NOTIFICATION_PERMISSION,
            )
            return
        }
        postWorkoutNotification(payload)
    }

    private fun postWorkoutNotification(payload: WorkoutNotificationPayload) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureWorkoutNotificationChannel(manager)

        val openIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_OPEN_ACTIVE_WORKOUT_DRAFT
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_OPEN_ACTIVE_WORKOUT_DRAFT, true)
        }
        val pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        val contentIntent = PendingIntent.getActivity(
            this,
            WORKOUT_NOTIFICATION_ID,
            openIntent,
            pendingFlags,
        )

        val exerciseBitmap = loadFlutterAssetBitmap(payload.exerciseAssetPath)
            ?: loadFlutterAssetBitmap(payload.appIconAssetPath)
            ?: BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, WORKOUT_NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_fitlog)
            .setContentTitle(payload.title)
            .setContentText(payload.body)
            .setContentIntent(contentIntent)
            .setLargeIcon(exerciseBitmap)
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(false)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setCategory(Notification.CATEGORY_STATUS)
            .build()

        manager.notify(WORKOUT_NOTIFICATION_ID, notification)
    }

    private fun cancelWorkoutNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(WORKOUT_NOTIFICATION_ID)
    }

    private fun ensureWorkoutNotificationChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val channel = NotificationChannel(
            WORKOUT_NOTIFICATION_CHANNEL_ID,
            "Workout in progress",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows the current FitLog workout set."
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun loadFlutterAssetBitmap(assetPath: String): Bitmap? {
        if (assetPath.isBlank()) {
            return null
        }
        return try {
            val assetKey = FlutterInjector.instance()
                .flutterLoader()
                .getLookupKeyForAsset(assetPath)
            assets.open(assetKey).use { BitmapFactory.decodeStream(it) }
        } catch (_: Exception) {
            null
        }
    }

    private data class WorkoutNotificationPayload(
        val title: String,
        val body: String,
        val appIconAssetPath: String,
        val exerciseAssetPath: String,
    ) {
        companion object {
            fun from(arguments: Any?): WorkoutNotificationPayload? {
                val map = arguments as? Map<*, *> ?: return null
                val title = map["title"]?.toString()?.trim().orEmpty()
                val body = map["body"]?.toString()?.trim().orEmpty()
                val appIconAssetPath = map["appIconAssetPath"]?.toString().orEmpty()
                val exerciseAssetPath = map["exerciseAssetPath"]?.toString().orEmpty()
                if (title.isEmpty() || body.isEmpty()) {
                    return null
                }
                return WorkoutNotificationPayload(
                    title = title,
                    body = body,
                    appIconAssetPath = appIconAssetPath,
                    exerciseAssetPath = exerciseAssetPath,
                )
            }
        }
    }

    companion object {
        private const val WORKOUT_NOTIFICATION_CHANNEL = "fitlog.local/workout_notification"
        private const val WORKOUT_NOTIFICATION_CHANNEL_ID = "workout_session"
        private const val WORKOUT_NOTIFICATION_ID = 230601
        private const val REQUEST_NOTIFICATION_PERMISSION = 230602
        private const val ACTION_OPEN_ACTIVE_WORKOUT_DRAFT =
            "com.fitlog.local.fitlog_local.OPEN_ACTIVE_WORKOUT_DRAFT"
        private const val EXTRA_OPEN_ACTIVE_WORKOUT_DRAFT = "open_active_workout_draft"
    }
}
