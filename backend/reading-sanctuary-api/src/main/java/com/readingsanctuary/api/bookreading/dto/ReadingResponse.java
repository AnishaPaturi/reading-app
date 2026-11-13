package com.readingsanctuary.api.bookreading.dto;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.book.enums.ReadingStatus;

public record ReadingResponse(
    UUID bookId,
    String title,
    ReadingStatus status,
    Integer currentPage,
    Integer totalPages,
    Double progressPercentage,
    LocalDate startedAt,
    LocalDate completedAt,
    OffsetDateTime lastReadAt,
    OffsetDateTime dnfAt,
    String dnfReason,
    String dnfNotes
) {}
