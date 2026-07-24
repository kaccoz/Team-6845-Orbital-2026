package com.example.crumb

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class CrumbWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val streak = widgetData.getInt("streak", 0)
        val lastDoneStr = widgetData.getString("last_done", null)
        val lastDone = lastDoneStr?.toLongOrNull() ?: -1L

        val currentTime = System.currentTimeMillis()

        // Calculate days inactive from epoch timestamp
        val daysInactive = if (lastDone <= 0) {
            -1
        } else {
            ((currentTime - lastDone) / (1000 * 60 * 60 * 24)).toInt()
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.crumb_widget)

            // Determine widget messaging and state visual
            val message: String
            val imageRes: Int

            when {
                // User has never completed a habit 
                lastDone <= 0L -> {
                    message = "Start your streak soon please..."
                    imageRes = R.drawable.warning_state
                }
                // Inactive for more than 5 days
                daysInactive > 5 -> {
                    message = "It's been $daysInactive days...💀"
                    imageRes = R.drawable.dead_state
                }
                // Active streak
                else -> {
                    message = "You're on fire!"
                    imageRes = R.drawable.fire_state
                }
            }

            views.setTextViewText(
                R.id.widget_top_text,
                message
            )

            views.setTextViewText(
                R.id.widget_bottom_text,
                "🔥$streak day streak"
            )
            views.setImageViewResource(R.id.widget_image, imageRes)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}