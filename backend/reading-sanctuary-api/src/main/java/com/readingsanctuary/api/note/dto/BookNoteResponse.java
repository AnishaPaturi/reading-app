package com.readingsanctuary.api.note.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record BookNoteResponse(
    UUID id,
    UUID bookId,
    String title,
    String content,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt
) {}
