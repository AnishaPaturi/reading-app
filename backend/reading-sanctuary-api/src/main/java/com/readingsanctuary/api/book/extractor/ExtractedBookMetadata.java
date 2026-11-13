package com.readingsanctuary.api.book.extractor;

public record ExtractedBookMetadata(
    String title,
    String author,
    String genre,
    String description,
    String isbn,
    Integer pages,
    Integer durationSeconds,
    String language,
    String coverBase64
) {
    public static ExtractedBookMetadata empty() {
        return new ExtractedBookMetadata(null, null, null, null, null, null, null, null, null);
    }
}
