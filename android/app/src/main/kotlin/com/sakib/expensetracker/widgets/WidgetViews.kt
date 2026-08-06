package com.sakib.expensetracker.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import com.sakib.expensetracker.MainActivity
import com.sakib.expensetracker.R

/** Four size buckets: 3x1 / 4x1 / 3x2 / 4x2 (primary sizes are 4x1 and 4x2). */
internal enum class WidgetBucket { COMPACT, WIDE, MEDIUM, LARGE }

/** Card corner-radius variant (small for 1-row, large for 2-row widgets). */
internal enum class WidgetRadius { SMALL, LARGE }

/**
 * Per-bucket typography / spacing. Text sizes are sp, paddings are dp (they
 * are converted to px when applied). Larger buckets get larger type, padding
 * and corner radii so the widget re-lays-out instead of stretching.
 */
internal data class WidgetMetrics(
    val titleSp: Float,
    val amountSp: Float,
    val subTitleSp: Float,
    val subAmountSp: Float,
    val arrowSp: Float,
    val rootPadding: Int,
    val cardPadding: Int,
    val radius: WidgetRadius,
)

internal data class WidgetPalette(
    val background: Int,
    val text: Int,
    val income: Int,
    val expense: Int,
    val onBalance: Int,
    val onBalanceTitle: Int,
)

/**
 * Builds the widget's RemoteViews entirely from the pushed snapshot — it only
 * renders strings, never recomputes balances or re-formats currency.
 */
object WidgetViews {

    fun build(
        context: Context,
        appWidgetId: Int,
        options: Bundle?,
        snapshot: WidgetSnapshot?,
    ): RemoteViews {
        val bucket = bucketFor(context, appWidgetId, options)
        val metrics = metricsFor(bucket)
        val night = isNightMode(context)
        val palette = paletteFor(context, night)
        val views = RemoteViews(context.packageName, R.layout.widget_home)

        val rootPad = dp(context, metrics.rootPadding)
        val cardPad = dp(context, metrics.cardPadding)
        views.setViewPadding(R.id.root, rootPad, rootPad, rootPad, rootPad)
        views.setInt(R.id.root, "setBackgroundColor", palette.background)
        views.setViewPadding(
            R.id.balance_content,
            cardPad, cardPad, cardPad, cardPad,
        )
        views.setViewPadding(
            R.id.income_card,
            cardPad, cardPad, cardPad, cardPad,
        )
        views.setViewPadding(
            R.id.expense_card,
            cardPad, cardPad, cardPad, cardPad,
        )

        // Balance card uses the amber/orange gradient; income/expense use the
        // theme surfaces.
        views.setInt(
            R.id.balance_card,
            "setBackgroundResource",
            balanceCardDrawable(metrics.radius),
        )
        views.setInt(
            R.id.income_card,
            "setBackgroundResource",
            cardDrawable(night, metrics.radius),
        )
        views.setInt(
            R.id.expense_card,
            "setBackgroundResource",
            cardDrawable(night, metrics.radius),
        )

        views.setTextViewTextSize(
            R.id.balance_title,
            TypedValue.COMPLEX_UNIT_SP,
            metrics.titleSp,
        )
        views.setTextViewTextSize(
            R.id.income_title,
            TypedValue.COMPLEX_UNIT_SP,
            metrics.subTitleSp,
        )
        views.setTextViewTextSize(
            R.id.income_arrow,
            TypedValue.COMPLEX_UNIT_SP,
            metrics.arrowSp,
        )
        views.setTextViewTextSize(
            R.id.expense_title,
            TypedValue.COMPLEX_UNIT_SP,
            metrics.subTitleSp,
        )
        views.setTextViewTextSize(
            R.id.expense_arrow,
            TypedValue.COMPLEX_UNIT_SP,
            metrics.arrowSp,
        )

        views.setTextColor(R.id.balance_title, palette.onBalanceTitle)
        views.setTextColor(R.id.income_title, palette.income)
        views.setTextColor(R.id.income_arrow, palette.income)
        views.setTextColor(R.id.expense_title, palette.expense)
        views.setTextColor(R.id.expense_arrow, palette.expense)

        renderContent(views, metrics, palette, snapshot)
        bindClicks(context, views)
        return views
    }

    private fun renderContent(
        views: RemoteViews,
        metrics: WidgetMetrics,
        palette: WidgetPalette,
        snapshot: WidgetSnapshot?,
    ) {
        if (snapshot == null || snapshot.signedOut) {
            views.setTextViewText(R.id.balance_title, "Expense Tracker")
            views.setTextViewText(R.id.balance_amount, "Sign in to view")
            views.setTextColor(R.id.balance_amount, palette.onBalanceTitle)
            views.setTextViewText(R.id.income_title, "Income")
            views.setTextViewText(R.id.expense_title, "Expense")
            views.setTextViewText(R.id.income_arrow, "\u2191")
            views.setTextViewText(R.id.expense_arrow, "\u2193")
            views.setTextViewText(R.id.income_amount, "\u2014")
            views.setTextViewText(R.id.expense_amount, "\u2014")
            views.setTextColor(R.id.income_amount, palette.text)
            views.setTextColor(R.id.expense_amount, palette.text)
            return
        }

        views.setTextViewText(R.id.balance_title, "Balance")
        views.setTextViewText(R.id.balance_amount, snapshot.balance)
        views.setTextColor(R.id.balance_amount, palette.onBalance)
        views.setTextViewTextSize(
            R.id.balance_amount,
            TypedValue.COMPLEX_UNIT_SP,
            amountSizeFor(metrics.amountSp, snapshot.balance),
        )

        views.setTextViewText(R.id.income_title, "Income")
        views.setTextViewText(R.id.expense_title, "Expense")
        views.setTextViewText(R.id.income_arrow, "\u2191")
        views.setTextViewText(R.id.expense_arrow, "\u2193")

        views.setTextViewText(R.id.income_amount, snapshot.income)
        views.setTextColor(R.id.income_amount, palette.text)
        views.setTextViewTextSize(
            R.id.income_amount,
            TypedValue.COMPLEX_UNIT_SP,
            amountSizeFor(metrics.subAmountSp, snapshot.income),
        )
        views.setTextViewText(R.id.expense_amount, snapshot.expense)
        views.setTextColor(R.id.expense_amount, palette.text)
        views.setTextViewTextSize(
            R.id.expense_amount,
            TypedValue.COMPLEX_UNIT_SP,
            amountSizeFor(metrics.subAmountSp, snapshot.expense),
        )
    }

    // Shrinks an amount's font when the formatted string is long so large
    // values never overflow the card (mirrors _amountFontSize in the app).
    private fun amountSizeFor(base: Float, text: String): Float {
        val len = text.length
        var size = base
        if (len > 12) size = base * 0.85f
        if (len > 16) size = base * 0.72f
        if (len > 20) size = base * 0.60f
        return maxOf(size, base * 0.5f)
    }

    private fun bindClicks(context: Context, views: RemoteViews) {
        views.setOnClickPendingIntent(
            R.id.balance_card,
            launchIntent(context, MainActivity.ACTION_DASHBOARD, null, 1001),
        )
        views.setOnClickPendingIntent(
            R.id.income_card,
            launchIntent(context, MainActivity.ACTION_ADD_TRANSACTION, true, 1002),
        )
        views.setOnClickPendingIntent(
            R.id.expense_card,
            launchIntent(context, MainActivity.ACTION_ADD_TRANSACTION, false, 1003),
        )
    }

    private fun launchIntent(
        context: Context,
        action: String,
        isIncome: Boolean?,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = action
            if (isIncome != null) putExtra(MainActivity.EXTRA_IS_INCOME, isIncome)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun bucketFor(
        context: Context,
        appWidgetId: Int,
        options: Bundle?,
    ): WidgetBucket {
        var width = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, -1) ?: -1
        var height = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, -1) ?: -1
        // Some launchers store these dimensions as floats.
        if (width < 0) {
            width = options?.getFloat(
                AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,
                -1f,
            )?.toInt() ?: -1
        }
        if (height < 0) {
            height = options?.getFloat(
                AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,
                -1f,
            )?.toInt() ?: -1
        }
        if (width < 0 || height < 0) {
            val info = AppWidgetManager.getInstance(context).getAppWidgetInfo(appWidgetId)
            if (info != null) {
                if (width < 0) width = info.minWidth
                if (height < 0) height = info.minHeight
            }
        }
        val wide = width >= 310
        val tall = height >= 110
        return when {
            tall && wide -> WidgetBucket.LARGE // 5x2
            tall -> WidgetBucket.MEDIUM // 4x2
            wide -> WidgetBucket.WIDE // 5x1
            else -> WidgetBucket.COMPACT // 4x1 (and smaller on resize)
        }
    }

    private fun metricsFor(bucket: WidgetBucket): WidgetMetrics = when (bucket) {
        WidgetBucket.COMPACT -> WidgetMetrics(
            titleSp = 10f,
            amountSp = 22f,
            subTitleSp = 7f,
            subAmountSp = 9f,
            arrowSp = 9f,
            rootPadding = 3,
            cardPadding = 2,
            radius = WidgetRadius.SMALL,
        )
        WidgetBucket.WIDE -> WidgetMetrics(
            titleSp = 12f,
            amountSp = 28f,
            subTitleSp = 8f,
            subAmountSp = 10f,
            arrowSp = 10f,
            rootPadding = 6,
            cardPadding = 2,
            radius = WidgetRadius.SMALL,
        )
        WidgetBucket.MEDIUM -> WidgetMetrics(
            titleSp = 14f,
            amountSp = 36f,
            subTitleSp = 12f,
            subAmountSp = 17f,
            arrowSp = 15f,
            rootPadding = 12,
            cardPadding = 12,
            radius = WidgetRadius.LARGE,
        )
        WidgetBucket.LARGE -> WidgetMetrics(
            titleSp = 16f,
            amountSp = 46f,
            subTitleSp = 14f,
            subAmountSp = 20f,
            arrowSp = 18f,
            rootPadding = 16,
            cardPadding = 14,
            radius = WidgetRadius.LARGE,
        )
    }

    private fun cardDrawable(night: Boolean, radius: WidgetRadius): Int = when {
        night && radius == WidgetRadius.LARGE -> R.drawable.widget_card_24_dark
        night -> R.drawable.widget_card_16_dark
        radius == WidgetRadius.LARGE -> R.drawable.widget_card_24_light
        else -> R.drawable.widget_card_16_light
    }

    private fun balanceCardDrawable(radius: WidgetRadius): Int = when (radius) {
        WidgetRadius.LARGE -> R.drawable.widget_balance_gradient_large
        else -> R.drawable.widget_balance_gradient_small
    }

    private fun paletteFor(context: Context, night: Boolean): WidgetPalette {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            tryDynamicPalette(context, night)?.let { return it }
        }
        return if (night) darkPalette() else lightPalette()
    }

    private fun isNightMode(context: Context): Boolean {
        val mode = context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK
        return mode == Configuration.UI_MODE_NIGHT_YES
    }

    private fun lightPalette() = WidgetPalette(
        background = 0xFFF7F5EF.toInt(),
        text = 0xFF0F172A.toInt(),
        income = 0xFF16A34A.toInt(),
        expense = 0xFFF97316.toInt(),
        onBalance = 0xFFFFFFFF.toInt(),
        onBalanceTitle = 0xFFFFE8C2.toInt(),
    )

    private fun darkPalette() = WidgetPalette(
        background = 0xFF171410.toInt(),
        text = 0xFFECEDEE.toInt(),
        income = 0xFF4ADE80.toInt(),
        expense = 0xFFFB923C.toInt(),
        onBalance = 0xFFFFFFFF.toInt(),
        onBalanceTitle = 0xFFFFE8C2.toInt(),
    )

    // Material You dynamic colors (API 31+) for background and the neutral
    // amount text. The Balance card stays amber/orange and income/expense keep
    // the app's green/orange accents. Falls back to the fixed palettes above
    // if any system dynamic resource is unavailable. Note the framework
    // tonal-palette naming: 0 = lightest, 1000 = darkest.
    private fun tryDynamicPalette(context: Context, night: Boolean): WidgetPalette? {
        return try {
            if (night) {
                WidgetPalette(
                    background = colorOf(context, android.R.color.system_neutral1_900),
                    text = colorOf(context, android.R.color.system_neutral1_10),
                    income = 0xFF4ADE80.toInt(),
                    expense = 0xFFFB923C.toInt(),
                    onBalance = 0xFFFFFFFF.toInt(),
                    onBalanceTitle = 0xFFFFE8C2.toInt(),
                )
            } else {
                WidgetPalette(
                    background = colorOf(context, android.R.color.system_neutral1_50),
                    text = colorOf(context, android.R.color.system_neutral1_900),
                    income = 0xFF16A34A.toInt(),
                    expense = 0xFFF97316.toInt(),
                    onBalance = 0xFFFFFFFF.toInt(),
                    onBalanceTitle = 0xFFFFE8C2.toInt(),
                )
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun colorOf(context: Context, id: Int): Int =
        context.resources.getColor(id, null)

    private fun dp(context: Context, value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()
}
