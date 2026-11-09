package com.readingsanctuary.api.sync.dto;

import java.util.List;
import java.util.UUID;

import jakarta.validation.constraints.NotNull;

public record SyncPushRequest(
        @NotNull(message = "deviceId is required")
        UUID deviceId,

        @NotNull(message = "changes list is required")
        List<SyncChangeDto> changes
) {
}
