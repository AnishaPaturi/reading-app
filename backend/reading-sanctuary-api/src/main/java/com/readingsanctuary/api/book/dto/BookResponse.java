package com.readingsanctuary.api.book.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

public record BookResponse(

    UUID id,

    String title,

    String description,

    String language,

    String publisher,

    LocalDate publicationDate,

    String isbn,

    OffsetDateTime createdAt,

    OffsetDateTime updatedAt,

    String previousReadingStatus,

    OffsetDateTime deletedAt,

    Double rating,

    Integer ratingOutOf100,

    Integer spiceRating,

    String mood,

    String recommendation,

    BigDecimal purchasePrice,

    String currency,

    String acquisitionMethod,

    LocalDate purchaseDate,

    String tropes,

    String readingStatus,

    Integer currentPage,

    Integer totalPages,

    LocalDate startedAt,

    LocalDate completedAt

) {}
