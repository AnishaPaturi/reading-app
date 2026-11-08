package com.readingsanctuary.api.book.dto;

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

    OffsetDateTime updatedAt

) {}
