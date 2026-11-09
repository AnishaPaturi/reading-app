package com.readingsanctuary.api.analytics.dto;

import java.time.LocalDate;

import com.readingsanctuary.api.analytics.enums.GoalPeriod;
import com.readingsanctuary.api.analytics.enums.GoalType;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record ReadingGoalRequest(
        @NotNull(message = "Goal type is required")
        GoalType goalType,

        @Min(value = 1, message = "Target value must be greater than zero")
        int targetValue,

        @NotNull(message = "Period type is required")
        GoalPeriod periodType,

        @NotNull(message = "Start date is required")
        LocalDate startDate,

        LocalDate endDate
) {
}
