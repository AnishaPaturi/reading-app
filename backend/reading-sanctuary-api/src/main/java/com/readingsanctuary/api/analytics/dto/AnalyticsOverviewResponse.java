package com.readingsanctuary.api.analytics.dto;

public record AnalyticsOverviewResponse(
        long totalBooks,
        long completedBooks,
        long currentlyReading,
        long toRead,
        long dnfBooks,
        long readingMinutes,
        long audiobookMinutes,
        long ttsMinutes,
        long pagesAdvanced,
        int currentStreak,
        int longestStreak
) {
}
