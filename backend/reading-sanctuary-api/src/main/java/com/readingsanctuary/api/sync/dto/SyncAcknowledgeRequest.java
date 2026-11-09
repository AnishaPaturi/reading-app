package com.readingsanctuary.api.sync.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

public record SyncAcknowledgeRequest(
        @NotNull(message = "deviceId is required")
        UUID deviceId,

        @NotNull(message = "cursor is required")
        @PositiveOrZero(message = "cursor must be zero or positive")
        Long cursor
) {
}
