package com.readingsanctuary.api.storage.dto;

import java.util.UUID;

public record DownloadUrlResponse(
        UUID fileId,
        String downloadUrl,
        long expiresInSeconds,
        String fileName,
        String checksum
) {
}
