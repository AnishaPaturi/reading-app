package com.readingsanctuary.api.analytics.dto;

public record ListeningAnalyticsResponse(
        ListeningCategoryData audiobook,
        ListeningCategoryData tts,
        long combinedListeningMinutes
) {
    public record ListeningCategoryData(
            long totalMinutes,
            long sessions
    ) {
    }
}
