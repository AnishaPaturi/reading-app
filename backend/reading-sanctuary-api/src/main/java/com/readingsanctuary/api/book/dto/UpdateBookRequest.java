package com.readingsanctuary.api.book.dto;

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
    String isbn

) {}
