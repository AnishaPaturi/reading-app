package com.readingsanctuary.api.storage.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotNull;

public record CompleteUploadRequest(
        @NotNull(message = "fileId is required")
        UUID fileId,

        String checksum
) {
}
