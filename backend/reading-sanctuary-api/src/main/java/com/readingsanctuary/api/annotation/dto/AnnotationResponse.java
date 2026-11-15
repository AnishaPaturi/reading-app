package com.readingsanctuary.api.annotation.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.annotation.entity.Annotation;

public record AnnotationResponse(
    UUID id,
    UUID userId,
    UUID bookId,
    UUID bookFileId,
    String type,
    String selectedText,
    String noteText,
    String color,
    Integer pageNumber,
    String locationData,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt
) {
    public static AnnotationResponse fromEntity(Annotation entity) {
        return new AnnotationResponse(
            entity.getId(),
            entity.getUser().getId(),
            entity.getBook().getId(),
            entity.getBookFile().getId(),
            entity.getType().name(),
            entity.getSelectedText(),
            entity.getNoteText(),
            entity.getColor(),
            entity.getPageNumber(),
            entity.getLocationData(),
            entity.getCreatedAt(),
            entity.getUpdatedAt()
        );
    }
}
