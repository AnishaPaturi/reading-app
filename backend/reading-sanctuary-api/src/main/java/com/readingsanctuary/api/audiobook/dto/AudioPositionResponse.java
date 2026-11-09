package com.readingsanctuary.api.audiobook.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record AudioPositionResponse(
    UUID id,
    UUID bookId,
    UUID bookFileId,
    Long positionMs,
    Long durationMs,
    BigDecimal playbackSpeed,
    Boolean isCompleted,
    OffsetDateTime updatedAt
) {}
