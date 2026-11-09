package com.readingsanctuary.api.analytics.dto;

import java.time.LocalDate;
import java.util.List;

public record StreakResponse(
        int currentStreak,
        int longestStreak,
        LocalDate streakStartDate,
        LocalDate lastActiveDate,
        List<LocalDate> activeDays
) {
}
