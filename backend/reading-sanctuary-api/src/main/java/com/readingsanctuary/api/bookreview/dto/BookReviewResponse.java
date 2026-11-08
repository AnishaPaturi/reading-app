package com.readingsanctuary.api.bookreview.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record BookReviewResponse(
    UUID id,
    UUID bookId,
    Integer rating,
    String review,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt
) {}
