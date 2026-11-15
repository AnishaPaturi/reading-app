package com.readingsanctuary.api.audiobook.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.validation.constraints.NotNull;

public record ListeningSessionDto(
    UUID id,
    @NotNull UUID audiobookId,
    @NotNull OffsetDateTime startedAt,
    OffsetDateTime endedAt,
    Long actualListeningMs
) {}
