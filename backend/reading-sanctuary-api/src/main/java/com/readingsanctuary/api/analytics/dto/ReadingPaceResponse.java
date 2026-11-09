package com.readingsanctuary.api.analytics.dto;

public record ReadingPaceResponse(
        double pagesPerDay,
        double minutesPerDay,
        int activeDaysCount,
        long totalPagesAdvanced,
        long totalReadingMinutes
) {
}
