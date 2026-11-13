package com.readingsanctuary.api.book.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ConfirmBookRequest(
    @NotBlank(message = "Upload ID is required")
    String uploadId,

    @NotBlank(message = "Title is required")
    @Size(max = 500, message = "Title must not exceed 500 characters")
    String title,

    @Size(max = 255, message = "Author must not exceed 255 characters")
    String author,

    @Size(max = 100, message = "Genre must not exceed 100 characters")
    String genre,

    String description,

    Integer pages,

    String readingStatus,

    UUID existingBookId
) {}
