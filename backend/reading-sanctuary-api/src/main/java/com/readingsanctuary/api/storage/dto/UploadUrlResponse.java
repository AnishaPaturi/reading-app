package com.readingsanctuary.api.storage.dto;

import java.util.UUID;

public record UploadUrlResponse(
        UUID uploadId,
        UUID fileId,
        String objectKey,
        String uploadUrl,
        long expiresInSeconds
) {
}
