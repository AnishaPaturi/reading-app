package com.readingsanctuary.api.bookreading.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record ReadingHistoryResponse(
    UUID id,
    String previousStatus,
    String newStatus,
    Integer currentPage,
    OffsetDateTime changedAt
) {}
