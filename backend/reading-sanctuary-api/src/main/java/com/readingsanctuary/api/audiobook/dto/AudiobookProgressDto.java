package com.readingsanctuary.api.audiobook.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record AudiobookProgressDto(
    UUID audiobookId,
    UUID currentTrackId,
    Integer trackIndex,
    Long positionMs,
    Long totalDurationMs,
    BigDecimal playbackSpeed,
    Boolean completed,
    OffsetDateTime lastListenedAt
) {}
