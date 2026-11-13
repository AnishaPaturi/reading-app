package com.readingsanctuary.api.book.extractor;

import java.io.File;
import java.io.IOException;
import java.util.Locale;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;
import org.springframework.stereotype.Component;

@Component
public class PdfMetadataExtractor implements BookMetadataExtractor {

    @Override
    public boolean supports(String fileExtension) {
        return fileExtension != null && "pdf".equalsIgnoreCase(fileExtension.trim());
    }

    @Override
    public ExtractedBookMetadata extract(File file, String originalFileName) throws IOException {
        String title = null;
        String author = null;
        String description = null;
        int pages = 0;

        try (PDDocument document = Loader.loadPDF(file)) {
            pages = document.getNumberOfPages();
            PDDocumentInformation info = document.getDocumentInformation();

            if (info != null) {
                title = sanitize(info.getTitle());
                author = sanitize(info.getAuthor());
                description = sanitize(info.getSubject());
            }
        } catch (Exception e) {
            // PDFBox load error or password protected
            throw new IOException("Failed to parse PDF metadata: " + e.getMessage(), e);
        }

        if (title == null || title.isBlank()) {
            title = formatDefaultTitle(originalFileName);
        }

        return new ExtractedBookMetadata(
                title,
                author,
                "Non-Fiction",
                description,
                null,
                pages > 0 ? pages : null,
                null,
                "en",
                null
        );
    }

    private String sanitize(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String formatDefaultTitle(String originalFileName) {
        if (originalFileName == null || originalFileName.isBlank()) return "Untitled Book";
        String clean = originalFileName.replace("\\", "/");
        clean = clean.substring(clean.lastIndexOf('/') + 1);
        int dot = clean.lastIndexOf('.');
        if (dot > 0) {
            clean = clean.substring(0, dot);
        }
        return clean.replace('_', ' ').replace('-', ' ').trim();
    }
}
