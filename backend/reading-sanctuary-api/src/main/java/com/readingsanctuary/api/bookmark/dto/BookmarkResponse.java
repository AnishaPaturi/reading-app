package com.readingsanctuary.api.bookmark.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.common.enums.ReadingLocationType;

public record BookmarkResponse(
    UUID id,
    UUID bookId,
    UUID bookFileId,
    String label,
    String note,
    ReadingLocationType locationType,
    String locationValue,
    Integer pageNumber,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt
) {}
