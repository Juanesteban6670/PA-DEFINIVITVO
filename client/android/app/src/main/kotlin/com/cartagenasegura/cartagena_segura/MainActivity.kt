package com.cartagenasegura.cartagena_segura

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cartagena/report-reminder")
            .setMethodCallHandler { call, result ->
                val owner = call.argument<String>("owner")
                if (owner.isNullOrBlank()) {
                    result.error("missing_owner", "Falta la cuenta del recordatorio", null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "schedule" -> {
                        val dueAt = call.argument<Number>("dueAt")?.toLong()
                        if (dueAt == null) {
                            result.error("missing_date", "Falta la fecha del recordatorio", null)
                        } else {
                            ReportReminderReceiver.schedule(this, owner, dueAt)
                            if (Build.VERSION.SDK_INT >= 33 &&
                                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                                PackageManager.PERMISSION_GRANTED
                            ) {
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 701)
                            }
                            result.success(null)
                        }
                    }
                    "consume" -> {
                        val dueAt = call.argument<Number>("dueAt")?.toLong()
                        result.success(dueAt != null && ReportReminderReceiver.consume(this, owner, dueAt))
                    }
                    "cancel" -> {
                        ReportReminderReceiver.cancel(this, owner)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
