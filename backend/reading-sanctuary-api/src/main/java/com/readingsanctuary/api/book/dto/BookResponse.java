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

    LocalDate completedAt,

    Boolean hasCover,

    String coverUrl,

    OffsetDateTime coverUpdatedAt

) {
    public BookResponse(
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
    ) {
        this(
                id,
                title,
                description,
                language,
                publisher,
                publicationDate,
                isbn,
                createdAt,
                updatedAt,
                previousReadingStatus,
                deletedAt,
                rating,
                ratingOutOf100,
                spiceRating,
                mood,
                recommendation,
                purchasePrice,
                currency,
                acquisitionMethod,
                purchaseDate,
                tropes,
                readingStatus,
                currentPage,
                totalPages,
                startedAt,
                completedAt,
                false,
                null,
                null
        );
    }
}
