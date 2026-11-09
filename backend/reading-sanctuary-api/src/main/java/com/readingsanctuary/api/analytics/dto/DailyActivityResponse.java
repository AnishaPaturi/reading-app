package com.readingsanctuary.api.analytics.dto;

import java.time.LocalDate;

public record DailyActivityResponse(
        LocalDate date,
        long readingMinutes,
        long audiobookMinutes,
        long ttsMinutes,
        int pagesAdvanced,
        boolean active
) {
}
