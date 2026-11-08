package com.readingsanctuary.api.bookmetadata.dto;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.Set;
import java.util.UUID;

public record BookMetadataResponse(

    UUID id,
    String title,
    String isbn,
    String publisher,
    String language,
    LocalDate publicationDate,
    String description,

    Set<AuthorResponse> authors,
    Set<GenreResponse> genres,

    String coverUrl,
    OffsetDateTime coverUpdatedAt

) {}
