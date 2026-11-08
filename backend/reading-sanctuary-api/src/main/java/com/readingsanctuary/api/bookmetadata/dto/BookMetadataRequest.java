package com.readingsanctuary.api.bookmetadata.dto;

import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;

import jakarta.validation.constraints.Size;

public record BookMetadataRequest(

    @Size(max = 500)
    String title,

    @Size(max = 20)
    String isbn,

    @Size(max = 255)
    String publisher,

    @Size(max = 50)
    String language,

    LocalDate publicationDate,

    String description,

    Set<UUID> authorIds,

    Set<UUID> genreIds

) {}
