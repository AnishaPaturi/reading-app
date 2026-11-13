package com.readingsanctuary.api.book.dto;

public record BookUploadResponse(
    String uploadId,
    String fileName,
    String format,
    String title,
    String author,
    String genre,
    String description,
    String isbn,
    Integer pages,
    Integer durationSeconds,
    String language,
    String coverBase64
) {}
