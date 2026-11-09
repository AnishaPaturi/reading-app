package com.readingsanctuary.api.text.service;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.apache.tika.Tika;
import org.apache.tika.exception.TikaException;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.bookfile.service.LocalFileStorageService;
import com.readingsanctuary.api.text.dto.ExtractedTextResponse;
import com.readingsanctuary.api.text.dto.TextChunkResponse;

@Service
public class DocumentTextExtractionService {

    private static final Set<String> SUPPORTED_FORMATS = Set.of("pdf", "epub", "docx");
    private static final int MAX_STRING_LENGTH = 5 * 1024 * 1024; // 5 MB max extracted text
    private static final int TARGET_CHUNK_LENGTH = 2000;
    private static final int CHUNKS_PER_CHAPTER = 10;
    private static final int CACHE_LIMIT = 50;

    private final BookRepository bookRepository;
    private final BookFileRepository fileRepository;
    private final LocalFileStorageService storageService;
    private final Tika tika;

    // Cache of extracted and chunked document text: fileId -> List of all chunks
    private final Map<UUID, List<String>> documentChunksCache = new ConcurrentHashMap<>();

    public DocumentTextExtractionService(
            BookRepository bookRepository,
            BookFileRepository fileRepository,
            LocalFileStorageService storageService) {

        this.bookRepository = bookRepository;
        this.fileRepository = fileRepository;
        this.storageService = storageService;

        this.tika = new Tika();
        this.tika.setMaxStringLength(MAX_STRING_LENGTH);
    }

    @Transactional(readOnly = true)
    public ExtractedTextResponse extractText(UUID userId, UUID bookId, UUID fileId, int chapter) {
        Book book = bookRepository.findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Book not found"));

        BookFile file = fileRepository.findByIdAndBook_Id(fileId, bookId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Book file not found"));

        String format = file.getFileFormat() != null ? file.getFileFormat().toLowerCase(Locale.ROOT) : "";
        if (!SUPPORTED_FORMATS.contains(format)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Text extraction is only supported for PDF, EPUB, and DOCX files. Got: " + file.getFileFormat()
            );
        }

        List<String> allChunks = documentChunksCache.computeIfAbsent(fileId, k -> {
            if (documentChunksCache.size() > CACHE_LIMIT) {
                documentChunksCache.clear();
            }
            return extractAndChunkDocument(file);
        });

        int requestedChapter = Math.max(1, chapter);
        int totalChunks = allChunks.size();
        int totalChapters = Math.max(1, (int) Math.ceil((double) totalChunks / CHUNKS_PER_CHAPTER));

        if (totalChunks == 0) {
            return new ExtractedTextResponse(
                    bookId,
                    fileId,
                    format.toUpperCase(Locale.ROOT),
                    1,
                    book.getTitle() + " - Chapter 1",
                    Collections.emptyList(),
                    false
            );
        }

        int startIndex = (requestedChapter - 1) * CHUNKS_PER_CHAPTER;
        if (startIndex >= totalChunks) {
            // Requested beyond available chapters
            return new ExtractedTextResponse(
                    bookId,
                    fileId,
                    format.toUpperCase(Locale.ROOT),
                    requestedChapter,
                    book.getTitle() + " - Chapter " + requestedChapter,
                    Collections.emptyList(),
                    false
            );
        }

        int endIndex = Math.min(totalChunks, startIndex + CHUNKS_PER_CHAPTER);
        List<TextChunkResponse> chapterChunks = new ArrayList<>();
        int chunkIdxInChapter = 0;
        for (int i = startIndex; i < endIndex; i++) {
            chapterChunks.add(new TextChunkResponse(chunkIdxInChapter++, allChunks.get(i)));
        }

        boolean hasNextChapter = endIndex < totalChunks;

        return new ExtractedTextResponse(
                bookId,
                fileId,
                format.toUpperCase(Locale.ROOT),
                requestedChapter,
                book.getTitle() + " - Chapter " + requestedChapter,
                chapterChunks,
                hasNextChapter
        );
    }

    public void invalidateCache(UUID fileId) {
        documentChunksCache.remove(fileId);
    }

    private List<String> extractAndChunkDocument(BookFile file) {
        Resource resource;
        try {
            resource = storageService.load(file.getStorageKey());
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Stored file not found");
        }

        String rawText;
        try (InputStream is = resource.getInputStream()) {
            rawText = tika.parseToString(is);
        } catch (TikaException | IOException e) {
            throw new ResponseStatusException(
                    HttpStatus.UNPROCESSABLE_ENTITY,
                    "Failed to extract text from document: " + e.getMessage()
            );
        }

        if (rawText == null || rawText.isBlank()) {
            return Collections.emptyList();
        }

        // Sanitize: normalize carriage returns, strip control characters
        String sanitized = rawText.replace("\r\n", "\n")
                .replace("\r", "\n")
                .replaceAll("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]", "");

        return splitIntoChunks(sanitized, TARGET_CHUNK_LENGTH);
    }

    public List<String> splitIntoChunks(String text, int maxChunkLength) {
        String[] paragraphs = text.split("\n\\s*\n");
        List<String> chunks = new ArrayList<>();
        StringBuilder current = new StringBuilder();

        for (String paragraph : paragraphs) {
            String trimmed = paragraph.trim();
            if (trimmed.isEmpty()) {
                continue;
            }

            if (trimmed.length() > maxChunkLength) {
                if (current.length() > 0) {
                    chunks.add(current.toString());
                    current = new StringBuilder();
                }

                for (int i = 0; i < trimmed.length(); i += maxChunkLength) {
                    int end = Math.min(i + maxChunkLength, trimmed.length());
                    chunks.add(trimmed.substring(i, end));
                }
                continue;
            }

            if (current.length() + trimmed.length() > maxChunkLength) {
                chunks.add(current.toString());
                current = new StringBuilder();
            }

            if (current.length() > 0) {
                current.append("\n\n");
            }
            current.append(trimmed);
        }

        if (current.length() > 0) {
            chunks.add(current.toString());
        }

        return chunks;
    }
}
