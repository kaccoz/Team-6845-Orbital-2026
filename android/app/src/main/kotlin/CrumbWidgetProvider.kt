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

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.crumb_widget)

            views.setTextViewText(
                R.id.widget_text,
                "🔥 $streak day streak"
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}