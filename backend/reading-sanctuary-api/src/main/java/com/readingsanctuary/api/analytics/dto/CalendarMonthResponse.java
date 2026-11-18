package com.readingsanctuary.api.analytics.dto;

import java.util.List;

public record CalendarMonthResponse(
        String month,
        int year,
        int monthValue,
        int daysRead,
        int daysMissed,
        int totalPagesRead,
        int totalMinutesRead,
        int bestStreakInMonth,
        List<CalendarDayResponse> days
) {}
