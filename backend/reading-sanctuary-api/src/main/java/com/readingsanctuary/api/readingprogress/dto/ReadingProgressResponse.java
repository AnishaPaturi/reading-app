package com.readingsanctuary.api.readingprogress.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record ReadingProgressResponse(
    UUID id,
    UUID userId,
    UUID bookId,
    UUID bookFileId,
    String format,
    Integer currentPage,
    Integer totalPages,
    String chapterHref,
    String epubCfi,
    Long audioPositionMs,
    Long audioDurationMs,
    BigDecimal progressPercentage,
    String positionData,
    OffsetDateTime lastOpenedAt,
    OffsetDateTime clientUpdatedAt,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt
) {}
