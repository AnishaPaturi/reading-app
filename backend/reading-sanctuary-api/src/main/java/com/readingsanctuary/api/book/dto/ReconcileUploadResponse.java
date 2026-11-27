package com.readingsanctuary.api.book.dto;

public record ReconcileUploadResponse(
        String status,
        String checksum,
        String uploadId,
        BookResponse book
) {}
