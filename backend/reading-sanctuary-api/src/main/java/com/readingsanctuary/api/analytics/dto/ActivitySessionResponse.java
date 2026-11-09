package com.readingsanctuary.api.analytics.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.analytics.enums.ActivityType;

public record ActivitySessionResponse(
        UUID id,
        UUID userId,
        UUID bookId,
        UUID bookFileId,
        ActivityType activityType,
        OffsetDateTime startedAt,
        OffsetDateTime endedAt,
        OffsetDateTime lastHeartbeatAt,
        int durationSeconds,
        Double startProgress,
        Double endProgress,
        int pagesAdvanced,
        boolean isActive,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt
) {
}
