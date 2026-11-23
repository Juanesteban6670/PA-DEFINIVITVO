package com.cartagenasegura.cartagena_segura

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build

class ReportReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val owner = intent.data?.lastPathSegment ?: return
        val dueAt = intent.getLongExtra("dueAt", 0)
        val state = preferences(context)
        if (dueAt == 0L || state.getLong("scheduled:$owner", 0) != dueAt ||
            state.getLong("delivered:$owner", 0) == dueAt) return
        val notifications = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 24 && !notifications.areNotificationsEnabled()) return

        val notification = if (Build.VERSION.SDK_INT >= 26) {
            val channel = NotificationChannel(
                CHANNEL, "Recordatorios de reportes", NotificationManager.IMPORTANCE_DEFAULT
            )
            notifications.createNotificationChannel(channel)
            if (notifications.getNotificationChannel(CHANNEL).importance ==
                NotificationManager.IMPORTANCE_NONE
            ) return
            Notification.Builder(context, CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val openApp = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE
        )
        notifications.notify(
            owner,
            NOTIFICATION_ID,
            notification.setSmallIcon(R.drawable.ic_report_reminder)
                .setContentTitle("Cartagena Segura")
                .setContentText("Tienes un reporte pendiente por enviar.")
                .setContentIntent(openApp)
                .setAutoCancel(true)
                .build()
        )
        state.edit().putLong("delivered:$owner", dueAt).apply()
    }

    companion object {
        private const val CHANNEL = "report_reminders"
        private const val NOTIFICATION_ID = 1

        private fun preferences(context: Context) =
            context.getSharedPreferences(CHANNEL, Context.MODE_PRIVATE)

        private fun alarmIntent(context: Context, owner: String, dueAt: Long = 0): PendingIntent =
            PendingIntent.getBroadcast(
                context, 0,
                Intent(context, ReportReminderReceiver::class.java)
                    .setData(Uri.Builder().scheme("cartagena-reminder").appendPath(owner).build())
                    .putExtra("dueAt", dueAt),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

        fun schedule(context: Context, owner: String, dueAt: Long) {
            cancel(context, owner)
            preferences(context).edit().putLong("scheduled:$owner", dueAt).apply()
            context.getSystemService(AlarmManager::class.java)
                .setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, dueAt, alarmIntent(context, owner, dueAt))
        }

        fun cancel(context: Context, owner: String) {
            preferences(context).edit().remove("scheduled:$owner").remove("delivered:$owner").apply()
            context.getSystemService(AlarmManager::class.java).cancel(alarmIntent(context, owner))
            context.getSystemService(NotificationManager::class.java).cancel(owner, NOTIFICATION_ID)
        }

        fun consume(context: Context, owner: String, dueAt: Long): Boolean {
            val state = preferences(context)
            if (state.getLong("scheduled:$owner", 0) != dueAt) return false
            val delivered = state.getLong("delivered:$owner", 0) == dueAt
            cancel(context, owner)
            return delivered
        }
    }
}
