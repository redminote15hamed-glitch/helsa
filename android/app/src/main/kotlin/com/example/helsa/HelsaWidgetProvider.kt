package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Theme-aware 3-metric widget.
 * Colors come from Flutter prefs: steps_color, cal_color, time_color, widget_bg, muted_color.
 * Background is drawn as a rounded bitmap so corners stay soft (setBackgroundColor would square them).
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
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        updateOne(context, appWidgetManager, appWidgetId, prefs)
    }

    private fun updateOne(
        context: Context,
        appWidgetManager: AppWidgetManager,
        id: Int,
        widgetData: SharedPreferences
    ) {
        try {
            val options = appWidgetManager.getAppWidgetOptions(id)
            val minH = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0
            val minW = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180) ?: 180

            val layoutId = when {
                minH >= 160 -> R.layout.helsa_widget_large
                minH >= 90 -> R.layout.helsa_widget_medium
                else -> R.layout.helsa_widget
            }

            val views = RemoteViews(context.packageName, layoutId)

            val steps = widgetData.getInt("steps", 0)
            val cal = widgetData.getInt("cal", 0)
            val mins = widgetData.getInt("mins", 0)
            val stepsGoal = widgetData.getInt("steps_goal", 8000).coerceAtLeast(1)
            val calGoal = widgetData.getInt("cal_goal", 300).coerceAtLeast(1)
            val minsGoal = widgetData.getInt("mins_goal", 30).coerceAtLeast(1)

            val stepsLabel = widgetData.getString("steps_label", "steps") ?: "steps"
            val calLabel = widgetData.getString("cal_label", "kcal") ?: "kcal"
            val timeLabel = widgetData.getString("time_label", "min") ?: "min"

            val stepsColor = widgetData.getInt("steps_color", Color.parseColor("#10B981"))
            val calColor = widgetData.getInt("cal_color", Color.parseColor("#FF8C42"))
            val timeColor = widgetData.getInt("time_color", Color.parseColor("#4C8DFF"))
            val bgColor = forceOpaque(widgetData.getInt("widget_bg", Color.parseColor("#FF121816")))
            val muted = widgetData.getInt("muted_color", Color.parseColor("#99FFFFFF"))

            val stepsPct = ((steps * 100.0) / stepsGoal).toInt().coerceIn(0, 999)
            val calPct = ((cal * 100.0) / calGoal).toInt().coerceIn(0, 999)
            val minsPct = ((mins * 100.0) / minsGoal).toInt().coerceIn(0, 999)

            // Soft rounded card background (keeps 22dp corners)
            val density = context.resources.displayMetrics.density
            val wPx = (minW.coerceAtLeast(120) * density).toInt().coerceIn(200, 1200)
            val hPx = (minH.coerceAtLeast(56) * density).toInt().coerceIn(100, 800)
            views.setImageViewBitmap(
                R.id.widget_bg_image,
                roundedRectBitmap(wPx, hPx, 22f * density, bgColor)
            )

            views.setTextViewText(R.id.tv_steps, steps.toString())
            views.setTextViewText(R.id.tv_cal, cal.toString())
            views.setTextViewText(R.id.tv_time, mins.toString())
            views.setTextViewText(R.id.tv_steps_label, stepsLabel)
            views.setTextViewText(R.id.tv_cal_label, calLabel)
            views.setTextViewText(R.id.tv_time_label, timeLabel)

            views.setTextColor(R.id.tv_steps, stepsColor)
            views.setTextColor(R.id.tv_cal, calColor)
            views.setTextColor(R.id.tv_time, timeColor)
            views.setTextColor(R.id.tv_steps_label, muted)
            views.setTextColor(R.id.tv_cal_label, muted)
            views.setTextColor(R.id.tv_time_label, muted)

            // Icon glyph + soft halo disk
            tint(views, R.id.iv_steps, stepsColor)
            tint(views, R.id.iv_cal, calColor)
            tint(views, R.id.iv_time, timeColor)
            tint(views, R.id.iv_steps_disk, withAlpha(stepsColor, 0x33))
            tint(views, R.id.iv_cal_disk, withAlpha(calColor, 0x33))
            tint(views, R.id.iv_time_disk, withAlpha(timeColor, 0x33))

            if (layoutId == R.layout.helsa_widget_medium ||
                layoutId == R.layout.helsa_widget_large
            ) {
                views.setTextViewText(R.id.tv_steps_frac, "$steps / $stepsGoal")
                views.setTextViewText(R.id.tv_cal_frac, "$cal / $calGoal")
                views.setTextViewText(R.id.tv_time_frac, "$mins / $minsGoal")
                views.setTextViewText(R.id.tv_steps_pct, "$stepsPct%")
                views.setTextViewText(R.id.tv_cal_pct, "$calPct%")
                views.setTextViewText(R.id.tv_time_pct, "$minsPct%")
                views.setTextColor(R.id.tv_steps_frac, muted)
                views.setTextColor(R.id.tv_cal_frac, muted)
                views.setTextColor(R.id.tv_time_frac, muted)
                views.setTextColor(R.id.tv_steps_pct, stepsColor)
                views.setTextColor(R.id.tv_cal_pct, calColor)
                views.setTextColor(R.id.tv_time_pct, timeColor)
            }

            appWidgetManager.updateAppWidget(id, views)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    companion object {
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
            // If Flutter sent near-transparent surface, force readable card.
            val a = (color ushr 24) and 0xFF
            return if (a < 0xCC) (color and 0x00FFFFFF) or 0xF0000000.toInt() else color
        }

        fun roundedRectBitmap(width: Int, height: Int, radius: Float, color: Int): Bitmap {
            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = color
                style = Paint.Style.FILL
            }
            canvas.drawRoundRect(
                RectF(0f, 0f, width.toFloat(), height.toFloat()),
                radius,
                radius,
                paint,
            )
            return bmp
        }
    }
}
