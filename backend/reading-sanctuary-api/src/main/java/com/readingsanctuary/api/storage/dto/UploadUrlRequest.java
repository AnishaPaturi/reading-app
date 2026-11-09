package com.readingsanctuary.api.storage.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record UploadUrlRequest(
        @NotNull(message = "bookId is required")
        UUID bookId,

        @NotBlank(message = "fileName is required")
        String fileName,

        @NotBlank(message = "contentType is required")
        String contentType,

        @NotNull(message = "fileSize is required")
        @Positive(message = "fileSize must be positive")
        Long fileSize,

        String checksum
) {
}
