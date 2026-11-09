package com.readingsanctuary.api.tts.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record TtsPositionResponse(
    UUID id,
    UUID bookId,
    UUID bookFileId,
    Integer chapterIndex,
    Integer chunkIndex,
    Integer characterOffset,
    BigDecimal progressPercentage,
    OffsetDateTime updatedAt
) {}
