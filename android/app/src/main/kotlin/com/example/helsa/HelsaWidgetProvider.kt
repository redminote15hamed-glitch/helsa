package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Theme-aware 3-metric widget. Hardened so a failed bind never leaves
 * "Can't load widget" — falls back to compact layout / safe defaults.
 */
class HelsaWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            updateOne(context, appWidgetManager, id, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        updateOne(context, appWidgetManager, appWidgetId, prefs)
    }

    private fun updateOne(
        context: Context,
        appWidgetManager: AppWidgetManager,
        id: Int,
        widgetData: SharedPreferences
    ) {
        val options = try {
            appWidgetManager.getAppWidgetOptions(id)
        } catch (_: Exception) {
            null
        }
        val minH = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0
        val minW = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180) ?: 180

        val layoutCandidates = buildList {
            if (minH >= 160) add(R.layout.helsa_widget_large)
            if (minH >= 90) add(R.layout.helsa_widget_medium)
            add(R.layout.helsa_widget)
        }.distinct()

        var lastError: Exception? = null
        for (layoutId in layoutCandidates) {
            try {
                val views = buildViews(context, layoutId, minW, minH, widgetData)
                appWidgetManager.updateAppWidget(id, views)
                return
            } catch (e: Exception) {
                lastError = e
                Log.e(TAG, "layout $layoutId failed", e)
            }
        }

        // Last resort: empty-but-valid compact bind
        try {
            val views = RemoteViews(context.packageName, R.layout.helsa_widget)
            safeText(views, R.id.tv_steps, "—")
            safeText(views, R.id.tv_cal, "—")
            safeText(views, R.id.tv_time, "—")
            appWidgetManager.updateAppWidget(id, views)
        } catch (e: Exception) {
            Log.e(TAG, "fallback bind failed", e)
            lastError?.printStackTrace()
        }
    }

    private fun buildViews(
        context: Context,
        layoutId: Int,
        minW: Int,
        minH: Int,
        widgetData: SharedPreferences
    ): RemoteViews {
        val views = RemoteViews(context.packageName, layoutId)

        val steps = widgetData.getInt("steps", 0)
        val cal = widgetData.getInt("cal", 0)
        val mins = widgetData.getInt("mins", 0)
        val stepsGoal = widgetData.getInt("steps_goal", 8000).coerceAtLeast(1)
        val calGoal = widgetData.getInt("cal_goal", 300).coerceAtLeast(1)
        val minsGoal = widgetData.getInt("mins_goal", 30).coerceAtLeast(1)

        val stepsPct = ((steps * 100) / stepsGoal).coerceIn(0, 999)
        val calPct = ((cal * 100) / calGoal).coerceIn(0, 999)
        val minsPct = ((mins * 100) / minsGoal).coerceIn(0, 999)

        val stepsColor = widgetData.getInt("steps_color", Color.parseColor("#10B981"))
        val calColor = widgetData.getInt("cal_color", Color.parseColor("#F97316"))
        val timeColor = widgetData.getInt("time_color", Color.parseColor("#3B82F6"))
        val bgColor = forceOpaque(
            widgetData.getInt("widget_bg", Color.parseColor("#F0FFFFFF"))
        )
        val muted = widgetData.getInt("muted_color", Color.parseColor("#99000000"))

        val stepsLabel = widgetData.getString("steps_label", "steps") ?: "steps"
        val calLabel = widgetData.getString("cal_label", "kcal") ?: "kcal"
        val timeLabel = widgetData.getString("time_label", "min") ?: "min"

        // Soft rounded card background (capped size — avoids OOM / Can't load)
        try {
            val density = context.resources.displayMetrics.density
            val wPx = (minW.coerceAtLeast(120) * density).toInt().coerceIn(120, 600)
            val hPx = (minH.coerceAtLeast(56) * density).toInt().coerceIn(80, 400)
            views.setImageViewBitmap(
                R.id.widget_bg_image,
                roundedRectBitmap(wPx, hPx, 18f * density, bgColor)
            )
        } catch (e: Exception) {
            Log.w(TAG, "bg bitmap skipped", e)
        }

        safeText(views, R.id.tv_steps, steps.toString())
        safeText(views, R.id.tv_cal, cal.toString())
        safeText(views, R.id.tv_time, mins.toString())
        safeText(views, R.id.tv_steps_label, stepsLabel)
        safeText(views, R.id.tv_cal_label, calLabel)
        safeText(views, R.id.tv_time_label, timeLabel)

        safeColor(views, R.id.tv_steps, stepsColor)
        safeColor(views, R.id.tv_cal, calColor)
        safeColor(views, R.id.tv_time, timeColor)
        safeColor(views, R.id.tv_steps_label, muted)
        safeColor(views, R.id.tv_cal_label, muted)
        safeColor(views, R.id.tv_time_label, muted)

        tint(views, R.id.iv_steps, stepsColor)
        tint(views, R.id.iv_cal, calColor)
        tint(views, R.id.iv_time, timeColor)
        tint(views, R.id.iv_steps_disk, withAlpha(stepsColor, 0x33))
        tint(views, R.id.iv_cal_disk, withAlpha(calColor, 0x33))
        tint(views, R.id.iv_time_disk, withAlpha(timeColor, 0x33))

        if (layoutId == R.layout.helsa_widget_medium ||
            layoutId == R.layout.helsa_widget_large
        ) {
            safeText(views, R.id.tv_steps_frac, "$steps / $stepsGoal")
            safeText(views, R.id.tv_cal_frac, "$cal / $calGoal")
            safeText(views, R.id.tv_time_frac, "$mins / $minsGoal")
            safeText(views, R.id.tv_steps_pct, "$stepsPct%")
            safeText(views, R.id.tv_cal_pct, "$calPct%")
            safeText(views, R.id.tv_time_pct, "$minsPct%")
            safeColor(views, R.id.tv_steps_frac, muted)
            safeColor(views, R.id.tv_cal_frac, muted)
            safeColor(views, R.id.tv_time_frac, muted)
            safeColor(views, R.id.tv_steps_pct, stepsColor)
            safeColor(views, R.id.tv_cal_pct, calColor)
            safeColor(views, R.id.tv_time_pct, timeColor)
        }

        return views
    }

    companion object {
        private const val TAG = "HelsaWidget"
        private const val PREFS = "HomeWidgetPreferences"

        fun safeText(views: RemoteViews, id: Int, text: String) {
            try {
                views.setTextViewText(id, text)
            } catch (_: Exception) {
            }
        }

        fun safeColor(views: RemoteViews, id: Int, color: Int) {
            try {
                views.setTextColor(id, color)
            } catch (_: Exception) {
            }
        }

        fun tint(views: RemoteViews, id: Int, color: Int) {
            try {
                views.setInt(id, "setColorFilter", color)
            } catch (_: Exception) {
            }
        }

        fun withAlpha(color: Int, alpha: Int): Int {
            return (color and 0x00FFFFFF) or ((alpha and 0xFF) shl 24)
        }

        fun forceOpaque(color: Int): Int {
            val a = (color ushr 24) and 0xFF
            return if (a < 0xCC) (color and 0x00FFFFFF) or 0xF0000000.toInt() else color
        }

        fun roundedRectBitmap(width: Int, height: Int, radius: Float, color: Int): Bitmap {
            val w = width.coerceIn(64, 600)
            val h = height.coerceIn(48, 400)
            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = color
                style = Paint.Style.FILL
            }
            canvas.drawRoundRect(
                RectF(0f, 0f, w.toFloat(), h.toFloat()),
                radius,
                radius,
                paint,
            )
            return bmp
        }
    }
}
