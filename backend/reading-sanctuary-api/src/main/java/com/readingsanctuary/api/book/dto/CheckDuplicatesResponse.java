package com.readingsanctuary.api.book.dto;

import java.util.List;
import java.util.UUID;

public record CheckDuplicatesResponse(
    List<DuplicateMatch> duplicates,
    List<String> existingChecksums,
    List<String> verifiedChecksums
) {
    public CheckDuplicatesResponse(List<DuplicateMatch> duplicates, List<String> existingChecksums) {
        this(duplicates, existingChecksums, List.of());
    }

    public record DuplicateMatch(
        String clientRefId,
        String checksum,
        UUID existingBookId,
        String existingBookTitle,
        String existingFileFormat,
        String existingFileName
    ) {}
}
