package com.sakib.expensetracker.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.os.Bundle
import android.widget.RemoteViews

/**
 * The Expense Tracker home-screen widget. Rendering is fully driven by the
 * snapshot Flutter writes to SharedPreferences ([WidgetPrefs]); this provider
 * never computes totals or re-formats currency.
 *
 * Updates are event-driven from the app (via [refreshAll], called through the
 * MethodChannel after every state change), whenever the widget is added or
 * resized, plus a conservative hourly fallback ([WidgetRefreshScheduler]).
 */
class ExpenseWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId, null)
        }
        WidgetRefreshScheduler.schedule(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId, newOptions)
    }

    override fun onEnabled(context: Context) {
        WidgetRefreshScheduler.schedule(context)
    }

    override fun onDisabled(context: Context) {
        WidgetRefreshScheduler.cancel(context)
    }

    companion object {
        /** Re-renders every live widget from the latest pushed snapshot. */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, ExpenseWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return
            for (appWidgetId in ids) {
                updateWidget(context, manager, appWidgetId, null)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
            options: Bundle?,
        ) {
            val snapshot = WidgetPrefs.readSnapshot(context)
            val views: RemoteViews =
                WidgetViews.build(context, appWidgetId, options, snapshot)
            manager.updateAppWidget(appWidgetId, views)
        }
    }
}

/**
 * Hourly fallback so widgets eventually refresh even if the app is never
 * opened again (event-driven pushes cover the common case).
 */
object WidgetRefreshScheduler {
    const val ACTION = "com.sakib.expensetracker.action.REFRESH_WIDGETS"
    private const val REQUEST_CODE = 0x77

    fun schedule(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setInexactRepeating(
            AlarmManager.RTC,
            System.currentTimeMillis() + AlarmManager.INTERVAL_HOUR,
            AlarmManager.INTERVAL_HOUR,
            refreshPendingIntent(context),
        )
    }

    fun cancel(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(refreshPendingIntent(context))
    }

    private fun refreshPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, WidgetRefreshReceiver::class.java).apply {
            action = ACTION
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

class WidgetRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != WidgetRefreshScheduler.ACTION) return
        ExpenseWidgetProvider.refreshAll(context)
    }
}
