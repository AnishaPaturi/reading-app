package com.readingsanctuary.api.readerposition.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.common.enums.ReadingLocationType;

public record ReadingPositionResponse(
    UUID id,
    UUID bookId,
    UUID bookFileId,
    ReadingLocationType locationType,
    String locationValue,
    Integer pageNumber,
    Integer totalPages,
    BigDecimal progressPercentage,
    OffsetDateTime updatedAt
) {}
