package com.readingsanctuary.api.audiobook.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record AudiobookResponseDto(
    UUID id,
    String title,
    String author,
    String narrator,
    String description,
    String coverPath,
    String folderPath,
    Long totalDurationMs,
    Integer totalTracks,
    String status,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt,
    List<AudioTrackDto> tracks
) {}
