package app.time_to.timeto

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import timeto.shared.reportApi

class TimerNotificationReceiver : BroadcastReceiver() {

    companion object {

        const val NOTIFICATION_ID_BREAK = 1
        const val NOTIFICATION_ID_OVERDUE = 2

        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val EXTRA_REQUEST_CODE = "request_code"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val manager = NotificationCenter.getManager()

        val requestCode = intent.getIntExtra(EXTRA_REQUEST_CODE, 0)

        val pIntent = PendingIntent.getActivity(
            context,
            requestCode,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_CLEAR_TASK
            },
            PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        /**
         * WARNING
         * Do not forget about channelTimeToBreak()/channelTimerOverdue()
         */
        val (iconId, color, channel) = when (requestCode) {
            NOTIFICATION_ID_BREAK -> {
                Triple(R.drawable.readme_notification_timer_checkmark, 0x34C759, NotificationCenter.channelTimeToBreak())
            }
            NOTIFICATION_ID_OVERDUE -> {
                Triple(R.drawable.readme_notification_alarm, 0x0055FF, NotificationCenter.channelTimerOverdue())
            }
            else -> {
                reportApi("TimerNotificationReceiver invalid request code $requestCode")
                throw Exception()
            }
        }

        val notification = NotificationCompat.Builder(context, channel.id)
            .setSmallIcon(iconId)
            .setColor(color)
            .setContentTitle(intent.getStringExtra(EXTRA_TITLE))
            .setContentText(intent.getStringExtra(EXTRA_TEXT))
            .setContentIntent(pIntent)
            .build()

        manager.notify(requestCode, notification)
    }
}