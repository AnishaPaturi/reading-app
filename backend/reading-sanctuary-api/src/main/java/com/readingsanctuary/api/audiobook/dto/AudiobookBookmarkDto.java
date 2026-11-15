package com.readingsanctuary.api.audiobook.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record AudiobookBookmarkDto(
    UUID id,
    @NotNull UUID audiobookId,
    UUID trackId,
    Integer trackIndex,
    @NotNull Long positionMs,
    @NotBlank String title,
    String note,
    String category,
    Boolean favorite,
    OffsetDateTime createdAt
) {}
