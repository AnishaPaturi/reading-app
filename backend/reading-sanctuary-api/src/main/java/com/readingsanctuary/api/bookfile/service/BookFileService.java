package com.readingsanctuary.api.bookfile.service;

import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.dto.BookFileResponse;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;

@Service
public class BookFileService {

    private static final Set<String> ALLOWED_FORMATS =
            Set.of("pdf", "epub", "docx", "mp3", "m4b");

    private final BookRepository bookRepository;
    private final BookFileRepository fileRepository;
    private final LocalFileStorageService storageService;

    public BookFileService(
            BookRepository bookRepository,
            BookFileRepository fileRepository,
            LocalFileStorageService storageService) {

        this.bookRepository = bookRepository;
        this.fileRepository = fileRepository;
        this.storageService = storageService;
    }

    @Transactional
    public BookFileResponse upload(
            UUID userId, UUID bookId, MultipartFile file) {

        Book book = getOwnedBook(bookId, userId);

        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Please select a file");
        }

        String originalName = file.getOriginalFilename();

        if (originalName == null || originalName.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Invalid file name");
        }

        String safeName = originalName.replace("\\", "/");
        safeName = safeName.substring(safeName.lastIndexOf('/') + 1);

        int dotIndex = safeName.lastIndexOf('.');

        if (dotIndex <= 0 || dotIndex == safeName.length() - 1) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "File extension is required");
        }

        String extension = safeName.substring(dotIndex + 1)
                .toLowerCase(Locale.ROOT);

        if (!ALLOWED_FORMATS.contains(extension)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Unsupported file format");
        }

        String storageKey = null;

        try {
            String checksum = calculateChecksum(file);

            storageKey = storageService.store(file, extension);

            BookFile bookFile = new BookFile();
            bookFile.setBook(book);
            bookFile.setFileName(safeName);
            bookFile.setFileFormat(extension.toUpperCase(Locale.ROOT));
            bookFile.setStorageKey(storageKey);
            bookFile.setFileSizeBytes(file.getSize());
            bookFile.setChecksum(checksum);

            BookFile saved = fileRepository.save(bookFile);

            return toResponse(saved);

        } catch (IOException | NoSuchAlgorithmException exception) {
            if (storageKey != null) {
                try {
                    storageService.delete(storageKey);
                } catch (IOException ignored) {
                    // Log this in production.
                }
            }

            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Could not store the uploaded file");
        }
    }

    @Transactional(readOnly = true)
    public List<BookFileResponse> getFiles(UUID userId, UUID bookId) {

        getOwnedBook(bookId, userId);

        return fileRepository.findAllByBook_Id(bookId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Resource download(UUID userId, UUID bookId, UUID fileId) {

        getOwnedBook(bookId, userId);

        BookFile file = getOwnedFile(bookId, fileId);

        try {
            return storageService.load(file.getStorageKey());
        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Stored file not found");
        }
    }

    @Transactional
    public void delete(UUID userId, UUID bookId, UUID fileId) {

        getOwnedBook(bookId, userId);

        BookFile file = getOwnedFile(bookId, fileId);

        try {
            storageService.delete(file.getStorageKey());
        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Could not delete the stored file");
        }

        fileRepository.delete(file);
    }

    private Book getOwnedBook(UUID bookId, UUID userId) {

        return bookRepository.findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));
    }

    private BookFile getOwnedFile(UUID bookId, UUID fileId) {

        return fileRepository.findByIdAndBook_Id(fileId, bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book file not found"));
    }

    private String calculateChecksum(MultipartFile file)
            throws IOException, NoSuchAlgorithmException {

        MessageDigest digest = MessageDigest.getInstance("SHA-256");

        try (var inputStream = file.getInputStream()) {
            byte[] buffer = new byte[8192];
            int bytesRead;

            while ((bytesRead = inputStream.read(buffer)) != -1) {
                digest.update(buffer, 0, bytesRead);
            }
        }

        return HexFormat.of().formatHex(digest.digest());
    }

    private BookFileResponse toResponse(BookFile file) {

        return new BookFileResponse(
                file.getId(),
                file.getFileName(),
                file.getFileFormat(),
                file.getFileSizeBytes(),
                file.getChecksum(),
                file.getUploadedAt()
        );
    }
}
