package com.sakib.expensetracker.widgets

import android.content.Context
import org.json.JSONObject

/**
 * The compact, preformatted snapshot Flutter pushes for the widget.
 *
 * Values are already formatted with the app's `formatCurrency` (currency
 * symbol included), so the widget renders them verbatim and never recomputes
 * totals or re-formats. This keeps the single source of truth in Dart.
 */
data class WidgetSnapshot(
    val uid: String?,
    val currency: String,
    val balance: String,
    val income: String,
    val expense: String,
) {
    val signedOut: Boolean
        get() = uid.isNullOrEmpty()
}

object WidgetPrefs {
    // Written by the Dart `shared_preferences` plugin, which stores keys in a
    // "FlutterSharedPreferences" file under a "flutter." prefix.
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY = "flutter.widget_snapshot"

    fun readSnapshot(context: Context): WidgetSnapshot? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY, null) ?: return null
        return try {
            val json = JSONObject(raw)
            WidgetSnapshot(
                uid = json.optString("uid").takeIf { it.isNotEmpty() },
                currency = json.optString("currency", "USD"),
                balance = json.optString("balance", ""),
                income = json.optString("income", ""),
                expense = json.optString("expense", ""),
            )
        } catch (_: Exception) {
            null
        }
    }
}
