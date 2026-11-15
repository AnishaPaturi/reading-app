package com.readingsanctuary.api.audiobook.dto;

import java.util.UUID;

public record AudioTrackDto(
    UUID id,
    String fileName,
    Integer trackOrder,
    Long durationMs,
    String format,
    String chapterTitle
) {}
