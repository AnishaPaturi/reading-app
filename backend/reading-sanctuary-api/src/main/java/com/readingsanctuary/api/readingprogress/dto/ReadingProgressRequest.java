package com.readingsanctuary.api.readingprogress.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;

public record ReadingProgressRequest(
    @NotBlank(message = "Format is required")
    String format,

    @PositiveOrZero(message = "Current page must be non-negative")
    Integer currentPage,

    @PositiveOrZero(message = "Total pages must be non-negative")
    Integer totalPages,

    String chapterHref,

    String epubCfi,

    @PositiveOrZero(message = "Audio position must be non-negative")
    Long audioPositionMs,

    @PositiveOrZero(message = "Audio duration must be non-negative")
    Long audioDurationMs,

    @DecimalMin(value = "0.0", inclusive = true, message = "Progress percentage must be >= 0")
    @DecimalMax(value = "100.0", inclusive = true, message = "Progress percentage must be <= 100")
    BigDecimal progressPercentage,

    String positionData,

    OffsetDateTime clientUpdatedAt
) {}
