package com.readingsanctuary.api.analytics.dto;

import java.util.List;

public record ActivitySummaryResponse(
        String period,
        int year,
        List<DailyActivityResponse> activities
) {
}
