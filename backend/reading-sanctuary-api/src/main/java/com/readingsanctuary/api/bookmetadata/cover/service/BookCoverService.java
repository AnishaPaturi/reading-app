package com.readingsanctuary.api.bookmetadata.cover.service;

import java.io.IOException;
import java.nio.file.Path;
import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
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
                recoverCover(userId, bookId);
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

        if (fileRepository == null || extractionService == null) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR, "Cover recovery service not configured");
        }

        List<BookFile> files = fileRepository.findAllByBook_Id(bookId);
        if (files.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "No files found for book");
        }

        BookFile targetFile = files.stream()
                .filter(f -> "EPUB".equalsIgnoreCase(f.getFileFormat()) || "PDF".equalsIgnoreCase(f.getFileFormat()))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "No PDF or EPUB file found for book"));

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
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Book file not found on disk");
        }

        ExtractedBookMetadata metadata;
        try {
            metadata = extractionService.extractMetadata(
                    filePath.toFile(),
                    targetFile.getFileName(),
                    targetFile.getFileFormat().toLowerCase(Locale.ROOT)
            );
        } catch (IOException e) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR, "Failed to extract metadata: " + e.getMessage());
        }

        if (metadata == null || metadata.coverBase64() == null || metadata.coverBase64().isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "No cover found in book file");
        }

        String coverData = metadata.coverBase64().trim();
        String contentType = "image/jpeg";
        String extension = "jpg";

        if (coverData.startsWith("data:")) {
            int semi = coverData.indexOf(';');
            int comma = coverData.indexOf(',');
            if (semi > 5 && comma > semi) {
                contentType = coverData.substring(5, semi).toLowerCase(Locale.ROOT);
                coverData = coverData.substring(comma + 1);
                extension = switch (contentType) {
                    case "image/png" -> "png";
                    case "image/webp" -> "webp";
                    default -> "jpg";
                };
            }
        }

        byte[] coverBytes;
        try {
            coverBytes = Base64.getDecoder().decode(coverData);
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR, "Corrupted cover data in book file");
        }

        if (coverBytes.length == 0 || coverBytes.length > maxSize) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Extracted cover exceeds maximum size limit");
        }

        if (!isValidImageBytes(coverBytes, extension)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Extracted cover signature is invalid");
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
        } catch (IOException e) {
            if (newStorageKey != null) {
                try {
                    storageService.delete(newStorageKey);
                } catch (IOException ignored) {}
            }
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR, "Failed to store recovered cover image");
        }

        if (oldStorageKey != null && !oldStorageKey.equals(newStorageKey)) {
            try {
                storageService.delete(oldStorageKey);
            } catch (IOException ignored) {}
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
