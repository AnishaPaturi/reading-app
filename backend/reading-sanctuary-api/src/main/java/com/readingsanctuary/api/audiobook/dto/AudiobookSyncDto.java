package com.readingsanctuary.api.audiobook.dto;

import java.util.List;
import java.util.UUID;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record AudiobookSyncDto(
    @NotNull UUID id,
    @NotBlank String title,
    String author,
    String narrator,
    String description,
    String coverPath,
    String folderPath,
    Long totalDurationMs,
    Integer totalTracks,
    String status,
    List<AudioTrackDto> tracks
) {}
