package com.readingsanctuary.api.book.dto;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;

public record CheckDuplicatesRequest(
    @NotEmpty(message = "Files list cannot be empty")
    List<FileCheckItem> files
) {
    public record FileCheckItem(
        String clientRefId,
        String checksum,
        String fileName,
        Long fileSizeBytes
    ) {}
}
