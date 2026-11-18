package com.readingsanctuary.api.book.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateBookRequest(

    @NotBlank(message = "Book title is required")
    @Size(max = 500, message = "Title cannot exceed 500 characters")
    String title,

    String description,

    @Size(max = 50, message = "Language cannot exceed 50 characters")
    String language,

    @Size(max = 255, message = "Publisher cannot exceed 255 characters")
    String publisher,

    LocalDate publicationDate,

    @Size(max = 20, message = "ISBN cannot exceed 20 characters")
    String isbn,

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
    public UpdateBookRequest(
        String title,
        String description,
        String language,
        String publisher,
        LocalDate publicationDate,
        String isbn
    ) {
        this(title, description, language, publisher, publicationDate, isbn,
             null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);
    }
}
