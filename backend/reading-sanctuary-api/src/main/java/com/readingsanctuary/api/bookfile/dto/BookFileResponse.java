package com.readingsanctuary.api.bookfile.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record BookFileResponse(
    UUID id,
    String fileName,
    String fileFormat,
    long fileSizeBytes,
    String checksum,
    OffsetDateTime uploadedAt,
    Long durationSeconds
) {
    public BookFileResponse(
            UUID id,
            String fileName,
            String fileFormat,
            long fileSizeBytes,
            String checksum,
            OffsetDateTime uploadedAt) {
        this(id, fileName, fileFormat, fileSizeBytes, checksum, uploadedAt, null);
    }
}
