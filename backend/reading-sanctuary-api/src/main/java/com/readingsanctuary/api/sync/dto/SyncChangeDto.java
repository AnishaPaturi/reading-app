package com.readingsanctuary.api.sync.dto;

import java.time.OffsetDateTime;

public record SyncChangeDto(
        Long cursor,
        String clientChangeId,
        String entityType,
        String entityId,
        String operation, // CREATE, UPDATE, DELETE
        Long version,
        Long baseVersion,
        String payload,
        OffsetDateTime changedAt
) {
}
