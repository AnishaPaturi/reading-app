package com.readingsanctuary.api.book.service;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Locale;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.readingsanctuary.api.book.extractor.BookMetadataExtractor;
import com.readingsanctuary.api.book.extractor.ExtractedBookMetadata;

@Service
public class BookMetadataExtractionService {

    private static final Logger log = LoggerFactory.getLogger(BookMetadataExtractionService.class);

    private final List<BookMetadataExtractor> extractors;
    private final BookCatalogueLookupService catalogueLookupService;

    public BookMetadataExtractionService(
            List<BookMetadataExtractor> extractors,
            BookCatalogueLookupService catalogueLookupService) {

        this.extractors = extractors;
        this.catalogueLookupService = catalogueLookupService;
    }

    public ExtractedBookMetadata extractMetadata(File file, String originalFileName, String format) throws IOException {
        String ext = format != null ? format.toLowerCase(Locale.ROOT) : getExtension(originalFileName);

        BookMetadataExtractor matchedExtractor = extractors.stream()
                .filter(extractor -> extractor.supports(ext))
                .findFirst()
                .orElse(null);

        ExtractedBookMetadata extracted;
        if (matchedExtractor != null) {
            try {
                extracted = matchedExtractor.extract(file, originalFileName);
            } catch (Exception e) {
                log.warn("Metadata extractor failed for {}: {}", originalFileName, e.getMessage());
                extracted = new ExtractedBookMetadata(
                        formatDefaultTitle(originalFileName),
                        null,
                        "Other",
                        null,
                        null,
                        null,
                        null,
                        "en",
                        null
                );
            }
        } else {
            extracted = new ExtractedBookMetadata(
                    formatDefaultTitle(originalFileName),
                    null,
                    "Other",
                    null,
                    null,
                    null,
                    null,
                    "en",
                    null
            );
        }

        // External catalogue lookup to fill in missing details (e.g. ISBN, author, description)
        try {
            return catalogueLookupService.enrichMetadata(extracted);
        } catch (Exception ignored) {
            return extracted;
        }
    }

    private String getExtension(String fileName) {
        if (fileName == null) return "";
        int dot = fileName.lastIndexOf('.');
        if (dot < 0 || dot >= fileName.length() - 1) return "";
        return fileName.substring(dot + 1).toLowerCase(Locale.ROOT);
    }

    private String formatDefaultTitle(String originalFileName) {
        if (originalFileName == null || originalFileName.isBlank()) return "Untitled Book";
        String clean = originalFileName.replace("\\", "/");
        clean = clean.substring(clean.lastIndexOf('/') + 1);
        int dot = clean.lastIndexOf('.');
        if (dot > 0) clean = clean.substring(0, dot);
        return clean.replace('_', ' ').replace('-', ' ').trim();
    }
}
