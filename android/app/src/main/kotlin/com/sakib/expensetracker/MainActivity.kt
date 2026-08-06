package com.sakib.expensetracker

import android.content.Intent
import android.os.Bundle
import com.sakib.expensetracker.widgets.ExpenseWidgetProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Launches both from the launcher and from home-screen widget taps.
 *
 * Widget taps carry a dedicated action (see the app widget provider). The
 * action is remembered here and handed to Flutter either as a push
 * (`pendingAction`, when the activity is already running) or a pull
 * (`getPendingAction`, on cold starts), so Flutter can route to the dashboard
 * or to Add Transaction with the correct tab preselected.
 */
class MainActivity : FlutterFragmentActivity() {

    companion object {
        const val ACTION_DASHBOARD = "com.sakib.expensetracker.action.DASHBOARD"
        const val ACTION_ADD_TRANSACTION =
            "com.sakib.expensetracker.action.ADD_TRANSACTION"
        const val EXTRA_IS_INCOME = "extra_is_income"

        private const val WIDGET_CHANNEL = "com.sakib.expensetracker/widget"
    }

    private var widgetChannel: MethodChannel? = null
    private var pendingAction: String? = null
    private var pendingIsIncome: Boolean? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleWidgetIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL,
        )
        widgetChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingAction" -> {
                    val action = pendingAction
                    if (action != null) {
                        result.success(
                            mapOf(
                                "action" to action,
                                "isIncome" to (pendingIsIncome ?: false),
                            ),
                        )
                        pendingAction = null
                        pendingIsIncome = null
                    } else {
                        result.success(null)
                    }
                }
                "updateWidgets" -> {
                    // Dart just refreshed the snapshot in SharedPreferences;
                    // re-render every live widget from it.
                    ExpenseWidgetProvider.refreshAll(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleWidgetIntent(intent: Intent?) {
        when (intent?.action) {
            ACTION_ADD_TRANSACTION -> {
                pendingAction = ACTION_ADD_TRANSACTION
                pendingIsIncome = intent.getBooleanExtra(EXTRA_IS_INCOME, false)
                widgetChannel?.invokeMethod(
                    "pendingAction",
                    mapOf(
                        "action" to ACTION_ADD_TRANSACTION,
                        "isIncome" to (pendingIsIncome ?: false),
                    ),
                )
            }
            ACTION_DASHBOARD -> {
                pendingAction = ACTION_DASHBOARD
                pendingIsIncome = false
                widgetChannel?.invokeMethod(
                    "pendingAction",
                    mapOf("action" to ACTION_DASHBOARD, "isIncome" to false),
                )
            }
            else -> {
                // Normal launch (e.g. launcher icon, notifications): no routing.
                pendingAction = null
                pendingIsIncome = null
            }
        }
    }
}
