package com.readingsanctuary.api.bookreading.dto;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import com.readingsanctuary.api.book.enums.ReadingStatus;

import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Positive;

public record UpdateReadingRequest(

    ReadingStatus status,

    @PositiveOrZero
    Integer currentPage,

    @Positive
    Integer totalPages,

    LocalDate startedAt,

    LocalDate completedAt,

    OffsetDateTime dnfAt,

    String dnfReason,

    String dnfNotes

) {}
