package com.readingsanctuary.api.sync.dto;

public record SyncConflictDto(
        String clientChangeId,
        String entityType,
        String entityId,
        String reason,
        long serverVersion,
        String serverPayload,
        String message
) {
}
