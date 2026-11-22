package com.readingsanctuary.api.bookmetadata.cover.service;

import java.io.IOException;
import java.nio.file.Path;
import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.extractor.ExtractedBookMetadata;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.book.service.BookMetadataExtractionService;
import com.readingsanctuary.api.book.service.BookStorageService;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.bookfile.service.LocalFileStorageService;

@Service
public class BookCoverService {

    private static final Logger log = LoggerFactory.getLogger(BookCoverService.class);

    public record CoverDownload(
            Resource resource,
            String contentType,
            String fileName
    ) {}

    private final BookRepository bookRepository;
    private final LocalFileStorageService storageService;
    private final long maxSize;

    @Autowired(required = false)
    private BookFileRepository fileRepository;

    @Autowired(required = false)
    private BookMetadataExtractionService extractionService;

    @Autowired(required = false)
    private BookStorageService bookStorageService;

    public BookCoverService(
            BookRepository bookRepository,
            LocalFileStorageService storageService,
            @Value("${app.storage.cover-max-size:5242880}") long maxSize) {

        this(bookRepository, storageService, maxSize, null, null, null);
    }

    @Autowired
    public BookCoverService(
            BookRepository bookRepository,
            LocalFileStorageService storageService,
            @Value("${app.storage.cover-max-size:5242880}") long maxSize,
            @Autowired(required = false) BookFileRepository fileRepository,
            @Autowired(required = false) BookMetadataExtractionService extractionService,
            @Autowired(required = false) BookStorageService bookStorageService) {

        this.bookRepository = bookRepository;
        this.storageService = storageService;
        this.maxSize = maxSize;
        this.fileRepository = fileRepository;
        this.extractionService = extractionService;
        this.bookStorageService = bookStorageService;
    }

    @Transactional
    public void uploadCover(
            UUID userId,
            UUID bookId,
            MultipartFile file) {

        Book book = getOwnedBook(bookId, userId);

        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Cover image is required");
        }

        if (file.getSize() > maxSize) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Cover image must not exceed 5 MB");
        }

        String contentType = file.getContentType();

        if (contentType == null ||
                !contentType.matches("image/(jpeg|png|webp)")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Only JPEG, PNG and WebP are supported");
        }

        String extension = switch (contentType) {
            case "image/jpeg" -> "jpg";
            case "image/png" -> "png";
            case "image/webp" -> "webp";
            default -> throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Unsupported cover format");
        };

        validateImageSignature(file, extension);

        String oldStorageKey = book.getCoverStorageKey();
        String newStorageKey = null;

        try {
            newStorageKey = storageService.store(file, extension);

            book.setCoverStorageKey(newStorageKey);
            book.setCoverFileName("cover." + extension);
            book.setCoverContentType(contentType);
            book.setCoverUpdatedAt(OffsetDateTime.now());

            bookRepository.save(book);

        } catch (IOException exception) {

            if (newStorageKey != null) {
                try {
                    storageService.delete(newStorageKey);
                } catch (IOException ignored) {
                    // Log cleanup failure in production.
                }
            }

            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Could not save cover image");
        }

        // Delete the old cover only after the replacement is saved.
        if (oldStorageKey != null) {
            try {
                storageService.delete(oldStorageKey);
            } catch (IOException ignored) {
                // Log this for later cleanup.
            }
        }
    }

    @Transactional
    public CoverDownload getCover(UUID userId, UUID bookId) {

        Book book = getOwnedBook(bookId, userId);

        if (book.getCoverStorageKey() == null) {
            try {
                recoverCover(book);
                book = getOwnedBook(bookId, userId);
            } catch (Exception ignored) {
                // If recovery fails, fall through to 404
            }
        }

        if (book.getCoverStorageKey() == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Book cover not found");
        }

        try {
            Resource resource = storageService.load(book.getCoverStorageKey());

            String contentType = book.getCoverContentType();
            if (contentType == null || contentType.isBlank()) {
                contentType = "image/jpeg";
            }
            String fileName = book.getCoverFileName();
            if (fileName == null || fileName.isBlank()) {
                fileName = "cover.jpg";
            }

            return new CoverDownload(
                    resource,
                    contentType,
                    fileName
            );

        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Cover image not found");
        }
    }

    @Transactional
    public void recoverCover(UUID userId, UUID bookId) {
        Book book = getOwnedBook(bookId, userId);
        boolean recovered = recoverCover(book);
        if (!recovered && book.getCoverStorageKey() == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "No cover could be extracted for book");
        }
    }

    /**
     * Safely recovers or backfills the cover for a book record using its original stored file.
     * Does not overwrite an existing valid cover.
     * Does not create duplicate book records or reset reading progress / annotations.
     */
    @Transactional
    public boolean recoverCover(Book book) {
        if (book == null || (book.getCoverStorageKey() != null && !book.getCoverStorageKey().isBlank())) {
            return false;
        }

        if (fileRepository == null || extractionService == null) {
            log.warn("Cover recovery skipped: repository or extraction service not configured");
            return false;
        }

        List<BookFile> files = fileRepository.findAllByBook_Id(book.getId());
        if (files.isEmpty()) {
            return false;
        }

        BookFile targetFile = files.stream()
                .filter(f -> "EPUB".equalsIgnoreCase(f.getFileFormat()) || "PDF".equalsIgnoreCase(f.getFileFormat()))
                .findFirst()
                .orElse(null);

        if (targetFile == null || targetFile.getStorageKey() == null) {
            return false;
        }

        Path filePath = null;
        if (bookStorageService != null) {
            try {
                Path p = bookStorageService.getPath(targetFile.getStorageKey());
                if (java.nio.file.Files.exists(p)) {
                    filePath = p;
                }
            } catch (Exception ignored) {}
        }

        if (filePath == null) {
            try {
                Resource resource = storageService.load(targetFile.getStorageKey());
                if (resource.exists()) {
                    filePath = resource.getFile().toPath();
                }
            } catch (Exception ignored) {}
        }

        if (filePath == null || !java.nio.file.Files.exists(filePath)) {
            log.warn("Cover recovery: Book file not found on disk for book {}", book.getId());
            return false;
        }

        ExtractedBookMetadata metadata;
        try {
            metadata = extractionService.extractMetadata(
                    filePath.toFile(),
                    targetFile.getFileName(),
                    targetFile.getFileFormat().toLowerCase(Locale.ROOT)
            );
        } catch (Exception e) {
            log.warn("Failed to extract metadata during cover recovery for book {}: {}", book.getId(), e.getMessage());
            return false;
        }

        if (metadata == null || metadata.coverBase64() == null || metadata.coverBase64().isBlank()) {
            return false;
        }

        String coverData = metadata.coverBase64().trim();
        String contentType = "image/jpeg";
        String extension = "jpg";

        if (coverData.startsWith("data:")) {
            int comma = coverData.indexOf(',');
            if (comma > 0) {
                String meta = coverData.substring(5, comma).toLowerCase(Locale.ROOT);
                coverData = coverData.substring(comma + 1);
                if (meta.contains("image/png")) {
                    extension = "png";
                    contentType = "image/png";
                } else if (meta.contains("image/webp")) {
                    extension = "webp";
                    contentType = "image/webp";
                } else {
                    extension = "jpg";
                    contentType = "image/jpeg";
                }
            }
        }

        byte[] coverBytes;
        try {
            coverBytes = Base64.getDecoder().decode(coverData.trim());
        } catch (IllegalArgumentException e) {
            log.warn("Corrupted cover base64 data for book {}: {}", book.getId(), e.getMessage());
            return false;
        }

        if (coverBytes.length == 0 || coverBytes.length > maxSize) {
            log.warn("Extracted cover for book {} rejected due to invalid length {}", book.getId(), coverBytes.length);
            return false;
        }

        if (!isValidImageBytes(coverBytes, extension)) {
            log.warn("Extracted cover for book {} rejected: byte signature does not match {}", book.getId(), extension);
            return false;
        }

        String oldStorageKey = book.getCoverStorageKey();
        String newStorageKey = null;

        try {
            newStorageKey = storageService.storeBytes(coverBytes, extension);

            book.setCoverStorageKey(newStorageKey);
            book.setCoverFileName("cover." + extension);
            book.setCoverContentType(contentType);
            book.setCoverUpdatedAt(OffsetDateTime.now());

            bookRepository.save(book);
            log.info("Successfully recovered cover for book {} ({})", book.getId(), book.getTitle());
            return true;
        } catch (IOException e) {
            if (newStorageKey != null) {
                try {
                    storageService.delete(newStorageKey);
                } catch (IOException ignored) {}
            }
            log.error("Failed to store recovered cover image for book {}: {}", book.getId(), e.getMessage());
            return false;
        }
    }

    /**
     * Automatic startup backfill: regenerates covers for any existing stored books missing covers.
     * Runs safely in the background when the application finishes booting.
     */
    @EventListener(ApplicationReadyEvent.class)
    public void backfillMissingCoversOnStartup() {
        try {
            List<Book> booksWithoutCover = bookRepository.findAllByCoverStorageKeyIsNull();
            if (booksWithoutCover == null || booksWithoutCover.isEmpty()) {
                return;
            }
            log.info("Checking {} book(s) for missing cover backfill...", booksWithoutCover.size());
            int recovered = 0;
            for (Book book : booksWithoutCover) {
                try {
                    if (recoverCover(book)) {
                        recovered++;
                    }
                } catch (Exception ex) {
                    log.warn("Could not backfill cover for book {}: {}", book.getId(), ex.getMessage());
                }
            }
            if (recovered > 0) {
                log.info("Successfully backfilled covers for {} existing book(s).", recovered);
            }
        } catch (Throwable e) {
            log.warn("Cover backfill on startup skipped or encountered an issue: {}", e.getMessage());
        }
    }

    @Transactional
    public void deleteCover(UUID userId, UUID bookId) {

        Book book = getOwnedBook(bookId, userId);

        String storageKey = book.getCoverStorageKey();

        if (storageKey == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Book cover not found");
        }

        try {
            storageService.delete(storageKey);
        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Could not delete cover image");
        }

        book.setCoverStorageKey(null);
        book.setCoverFileName(null);
        book.setCoverContentType(null);
        book.setCoverUpdatedAt(null);

        bookRepository.save(book);
    }

    private Book getOwnedBook(UUID bookId, UUID userId) {

        return bookRepository.findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));
    }

    private void validateImageSignature(
            MultipartFile file, String extension) {

        try (var input = file.getInputStream()) {

            byte[] header = input.readNBytes(12);

            boolean valid = switch (extension) {
                case "jpg" ->
                        header.length >= 3 &&
                        (header[0] & 0xFF) == 0xFF &&
                        (header[1] & 0xFF) == 0xD8 &&
                        (header[2] & 0xFF) == 0xFF;

                case "png" ->
                        header.length >= 8 &&
                        (header[0] & 0xFF) == 0x89 &&
                        header[1] == 0x50 &&
                        header[2] == 0x4E &&
                        header[3] == 0x47;

                case "webp" ->
                        header.length >= 12 &&
                        header[0] == 'R' &&
                        header[1] == 'I' &&
                        header[2] == 'F' &&
                        header[3] == 'F' &&
                        header[8] == 'W' &&
                        header[9] == 'E' &&
                        header[10] == 'B' &&
                        header[11] == 'P';

                default -> false;
            };

            if (!valid) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "File content does not match the image format");
            }

        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Could not read cover image");
        }
    }

    private boolean isValidImageBytes(byte[] bytes, String extension) {
        if (bytes == null || bytes.length < 4) return false;
        return switch (extension) {
            case "jpg", "jpeg" ->
                    bytes.length >= 3 &&
                    (bytes[0] & 0xFF) == 0xFF &&
                    (bytes[1] & 0xFF) == 0xD8 &&
                    (bytes[2] & 0xFF) == 0xFF;
            case "png" ->
                    bytes.length >= 8 &&
                    (bytes[0] & 0xFF) == 0x89 &&
                    bytes[1] == 0x50 &&
                    bytes[2] == 0x4E &&
                    bytes[3] == 0x47;
            case "webp" ->
                    bytes.length >= 12 &&
                    bytes[0] == 'R' && bytes[1] == 'I' && bytes[2] == 'F' && bytes[3] == 'F' &&
                    bytes[8] == 'W' && bytes[9] == 'E' && bytes[10] == 'B' && bytes[11] == 'P';
            default -> false;
        };
    }
}
