package com.readingsanctuary.api.bookmetadata.cover.service;

import java.io.IOException;
import java.time.OffsetDateTime;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
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

    public BookCoverService(
            BookRepository bookRepository,
            LocalFileStorageService storageService,
            @Value("${app.storage.cover-max-size:5242880}") long maxSize) {

        this.bookRepository = bookRepository;
        this.storageService = storageService;
        this.maxSize = maxSize;
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

    @Transactional(readOnly = true)
    public CoverDownload getCover(UUID userId, UUID bookId) {

        Book book = getOwnedBook(bookId, userId);

        if (book.getCoverStorageKey() == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Book cover not found");
        }

        try {
            Resource resource = storageService.load(book.getCoverStorageKey());

            return new CoverDownload(
                    resource,
                    book.getCoverContentType(),
                    book.getCoverFileName()
            );

        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Cover image not found");
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
}
