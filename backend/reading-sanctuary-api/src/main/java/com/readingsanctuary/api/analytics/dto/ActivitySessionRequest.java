package com.readingsanctuary.api.analytics.dto;

import java.util.UUID;

import com.readingsanctuary.api.analytics.enums.ActivityType;

import jakarta.validation.constraints.NotNull;

public record ActivitySessionRequest(
        UUID bookId,
        UUID bookFileId,
        @NotNull(message = "Activity type is required")
        ActivityType activityType,
        Double progress
) {
}
