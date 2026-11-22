package com.readingsanctuary.api.analytics.dto;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;

public record StreakResponse(
        int currentStreak,
        int longestStreak,
        LocalDate streakStartDate,
        LocalDate lastActiveDate,
        List<LocalDate> activeDays,
        boolean isTodayComplete,
        int freezesAvailable,
        int freezesUsed,
        List<LocalDate> frozenDays,
        int momentumDaysActiveLast7,
        String momentumStatus,
        List<WeeklyDayStatus> weeklyActivity
) {
    public record WeeklyDayStatus(
            LocalDate date,
            String dayOfWeek,
            boolean isCompleted,
            boolean isToday,
            boolean isFuture,
            int minutesRead
    ) {}

    // Backwards-compatible constructor for existing tests and callers
    public StreakResponse(
            int currentStreak,
            int longestStreak,
            LocalDate streakStartDate,
            LocalDate lastActiveDate,
            List<LocalDate> activeDays
    ) {
        this(
                currentStreak,
                longestStreak,
                streakStartDate,
                lastActiveDate,
                activeDays,
                false,
                2,
                0,
                Collections.emptyList(),
                0,
                "Starting",
                Collections.emptyList()
        );
    }
}
