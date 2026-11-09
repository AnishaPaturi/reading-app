package com.readingsanctuary.api.text.dto;

import java.util.List;
import java.util.UUID;

public record ExtractedTextResponse(
        UUID bookId,
        UUID bookFileId,
        String format,
        int chapter,
        String title,
        List<TextChunkResponse> chunks,
        boolean hasNextChapter
) {
}
