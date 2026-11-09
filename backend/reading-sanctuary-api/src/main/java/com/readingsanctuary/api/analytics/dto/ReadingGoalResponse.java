package com.readingsanctuary.api.analytics.dto;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.analytics.enums.GoalPeriod;
import com.readingsanctuary.api.analytics.enums.GoalType;

public record ReadingGoalResponse(
        UUID id,
        UUID userId,
        GoalType goalType,
        int targetValue,
        GoalPeriod periodType,
        LocalDate startDate,
        LocalDate endDate,
        boolean isActive,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt
) {
}
