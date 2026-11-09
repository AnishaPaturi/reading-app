package com.readingsanctuary.api.storage.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.storage.enums.StorageProvider;
import com.readingsanctuary.api.storage.enums.UploadStatus;

public record StorageFileResponse(
        UUID fileId,
        UUID bookId,
        String fileName,
        String fileFormat,
        long fileSizeBytes,
        StorageProvider storageProvider,
        UploadStatus storageStatus,
        String checksum,
        OffsetDateTime uploadedAt,
        OffsetDateTime cloudVerifiedAt
) {
}
