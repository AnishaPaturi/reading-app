package com.example.reading_sanctuary_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class AudiobookNowPlayingWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_audiobook_now_playing).apply {
                val title = widgetData.getString("now_playing_title", "No Audiobook Playing")
                val author = widgetData.getString("now_playing_author", "Reading Sanctuary")
                val coverPath = widgetData.getString("now_playing_cover", null)
                val posMs = widgetData.getInt("position_ms", 0)
                val durMs = widgetData.getInt("duration_ms", 0)

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_author, author)

                val progress = if (durMs > 0) ((posMs.toFloat() / durMs.toFloat()) * 100).toInt() else 0
                setProgressBar(R.id.widget_progress, 100, progress, false)

                if (!coverPath.isNullOrEmpty()) {
                    val file = File(coverPath)
                    if (file.exists()) {
                        val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.widget_cover, bitmap)
                        }
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
