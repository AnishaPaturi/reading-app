package com.readingsanctuary.api.sync.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record DeviceResponse(
        UUID id,
        String deviceName,
        String platform,
        long lastSyncCursor,
        OffsetDateTime lastSeenAt,
        boolean isActive,
        OffsetDateTime createdAt
) {
}
