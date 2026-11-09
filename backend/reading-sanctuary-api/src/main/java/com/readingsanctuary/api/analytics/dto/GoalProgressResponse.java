package com.readingsanctuary.api.analytics.dto;

import java.util.UUID;

import com.readingsanctuary.api.analytics.enums.GoalType;

public record GoalProgressResponse(
        UUID goalId,
        GoalType goalType,
        int targetValue,
        int currentValue,
        double percentage,
        int remainingValue,
        boolean completed
) {
}
