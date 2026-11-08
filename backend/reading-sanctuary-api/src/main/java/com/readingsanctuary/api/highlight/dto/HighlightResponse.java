package com.readingsanctuary.api.highlight.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.common.enums.HighlightColor;
import com.readingsanctuary.api.common.enums.ReadingLocationType;

public record HighlightResponse(
    UUID id,
    UUID bookId,
    UUID bookFileId,
    String selectedText,
    ReadingLocationType locationType,
    String startLocation,
    String endLocation,
    Integer pageNumber,
    HighlightColor color,
    String annotationNote,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt
) {}
