package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.graphics.Color
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Single-metric steps widget — same theme pipeline as the triple widget. */
class HelsaStepsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.helsa_widget_steps)
                val steps = widgetData.getInt("steps", 0)
                val goal = widgetData.getInt("steps_goal", 8000).coerceAtLeast(1)
                val pct = ((steps * 100.0) / goal).toInt().coerceIn(0, 999)
                val stepsColor = widgetData.getInt("steps_color", Color.parseColor("#10B981"))
                val bgColor = HelsaWidgetProvider.forceOpaque(
                    widgetData.getInt("widget_bg", Color.parseColor("#FF121816"))
                )
                val muted = widgetData.getInt("muted_color", Color.parseColor("#99FFFFFF"))
                val unit = widgetData.getString("steps_label", "steps") ?: "steps"

                val density = context.resources.displayMetrics.density
                val options = appWidgetManager.getAppWidgetOptions(id)
                val minW = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110) ?: 110
                val minH = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110) ?: 110
                val wPx = (minW.coerceAtLeast(100) * density).toInt().coerceIn(160, 900)
                val hPx = (minH.coerceAtLeast(100) * density).toInt().coerceIn(160, 900)
                views.setImageViewBitmap(
                    R.id.widget_bg_image,
                    HelsaWidgetProvider.roundedRectBitmap(wPx, hPx, 22f * density, bgColor)
                )

                views.setTextViewText(R.id.tv_steps_big, steps.toString())
                views.setTextViewText(R.id.tv_steps_unit, unit)
                views.setTextViewText(R.id.tv_steps_pct_capsule, "$pct%")
                views.setTextColor(R.id.tv_steps_big, stepsColor)
                views.setTextColor(R.id.tv_steps_unit, muted)
                views.setTextColor(R.id.tv_steps_pct_capsule, stepsColor)

                HelsaWidgetProvider.tint(views, R.id.iv_steps_big, stepsColor)
                HelsaWidgetProvider.tint(
                    views,
                    R.id.iv_steps_disk,
                    HelsaWidgetProvider.withAlpha(stepsColor, 0x33),
                )

                try {
                    views.setProgressBar(R.id.bar_steps_capsule, 100, pct.coerceAtMost(100), false)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        views.setColorStateList(
                            R.id.bar_steps_capsule,
                            "setProgressTintList",
                            ColorStateList.valueOf(stepsColor)
                        )
                        views.setColorStateList(
                            R.id.bar_steps_capsule,
                            "setProgressBackgroundTintList",
                            ColorStateList.valueOf(HelsaWidgetProvider.withAlpha(stepsColor, 0x33))
                        )
                    }
                } catch (_: Exception) {
                }

                appWidgetManager.updateAppWidget(id, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
