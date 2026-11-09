package com.readingsanctuary.api.storage.service;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.storage.config.StorageConfig;
import com.readingsanctuary.api.storage.dto.*;
import com.readingsanctuary.api.storage.enums.StorageProvider;
import com.readingsanctuary.api.storage.enums.UploadStatus;

@Service
@Transactional
public class CloudStorageService {

    private final BookRepository bookRepository;
    private final BookFileRepository bookFileRepository;
    private final StorageProviderFactory storageFactory;
    private final StorageConfig storageConfig;
    private final FileIntegrityService integrityService;

    public CloudStorageService(
            BookRepository bookRepository,
            BookFileRepository bookFileRepository,
            StorageProviderFactory storageFactory,
            StorageConfig storageConfig,
            FileIntegrityService integrityService) {
        this.bookRepository = bookRepository;
        this.bookFileRepository = bookFileRepository;
        this.storageFactory = storageFactory;
        this.storageConfig = storageConfig;
        this.integrityService = integrityService;
    }

    public UploadUrlResponse requestUploadUrl(UUID userId, UploadUrlRequest request) {
        Book book = bookRepository.findByIdAndCreatedBy_Id(request.bookId(), userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Book not found or access denied"));

        UUID fileId = UUID.randomUUID();
        String extension = getExtension(request.fileName());
        String format = extension.toUpperCase();

        // Object key convention: users/{userId}/books/{bookId}/files/{fileId}/{filename}
        String sanitizedName = sanitizeFilename(request.fileName());
        String objectKey = "users/%s/books/%s/files/%s/%s".formatted(userId, book.getId(), fileId, sanitizedName);

        StorageProvider provider = storageConfig.getResolvedProvider();
        StorageService storageService = storageFactory.getActiveStorageService();

        BookFile bookFile = new BookFile();
        bookFile.setBook(book);
        bookFile.setFileName(request.fileName());
        bookFile.setFileFormat(format);
        bookFile.setStorageKey(objectKey);
        bookFile.setFileSizeBytes(request.fileSize());
        bookFile.setChecksum(request.checksum());
        bookFile.setStorageProvider(provider.name());
        bookFile.setStorageStatus(UploadStatus.PENDING_UPLOAD.name());
        bookFileRepository.save(bookFile);

        Duration duration = Duration.ofMinutes(storageConfig.getS3().getPresignedUrlExpirationMinutes());
        String uploadUrl = storageService.generateUploadUrl(objectKey, request.contentType(), duration);

        return new UploadUrlResponse(
                UUID.randomUUID(),
                bookFile.getId(),
                objectKey,
                uploadUrl,
                duration.toSeconds()
        );
    }

    public StorageFileResponse completeUpload(UUID userId, CompleteUploadRequest request) {
        BookFile file = bookFileRepository.findById(request.fileId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "File record not found"));

        if (!file.getBook().getCreatedBy().getId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied to file");
        }

        StorageProvider provider = StorageProvider.fromString(file.getStorageProvider());
        StorageService storageService = storageFactory.getStorageService(provider);

        if (!storageService.exists(file.getStorageKey())) {
            file.setStorageStatus(UploadStatus.FAILED.name());
            bookFileRepository.save(file);
            throw new IllegalStateException("Uploaded file was not found in storage destination");
        }

        long actualSize = storageService.getObjectSize(file.getStorageKey());
        if (actualSize > 0) {
            file.setFileSizeBytes(actualSize);
        }

        if (request.checksum() != null && !request.checksum().isBlank()) {
            if (file.getChecksum() != null && !integrityService.verifyChecksum(request.checksum(), file.getChecksum())) {
                file.setStorageStatus(UploadStatus.FAILED.name());
                bookFileRepository.save(file);
                throw new IllegalArgumentException("File checksum verification failed");
            }
            file.setChecksum(request.checksum());
        }

        file.setStorageStatus(UploadStatus.VERIFIED.name());
        file.setCloudVerifiedAt(OffsetDateTime.now());
        bookFileRepository.save(file);

        return toStorageFileResponse(file);
    }

    @Transactional(readOnly = true)
    public DownloadUrlResponse generateDownloadUrl(UUID userId, UUID fileId) {
        BookFile file = bookFileRepository.findById(fileId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "File not found"));

        if (!file.getBook().getCreatedBy().getId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied to file");
        }

        StorageProvider provider = StorageProvider.fromString(file.getStorageProvider());
        StorageService storageService = storageFactory.getStorageService(provider);

        Duration duration = Duration.ofMinutes(storageConfig.getS3().getPresignedUrlExpirationMinutes());
        String downloadUrl = storageService.generateDownloadUrl(file.getStorageKey(), duration);

        return new DownloadUrlResponse(
                file.getId(),
                downloadUrl,
                duration.toSeconds(),
                file.getFileName(),
                file.getChecksum()
        );
    }

    public void deleteFile(UUID userId, UUID fileId) {
        BookFile file = bookFileRepository.findById(fileId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "File not found"));

        if (!file.getBook().getCreatedBy().getId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied to file");
        }

        file.setStorageStatus(UploadStatus.PENDING_DELETE.name());
        bookFileRepository.save(file);

        StorageProvider provider = StorageProvider.fromString(file.getStorageProvider());
        StorageService storageService = storageFactory.getStorageService(provider);

        try {
            storageService.delete(file.getStorageKey());
        } catch (Exception ignored) {
        }

        bookFileRepository.delete(file);
    }

    @Transactional(readOnly = true)
    public StorageFileResponse getFileStatus(UUID userId, UUID fileId) {
        BookFile file = bookFileRepository.findById(fileId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "File not found"));

        if (!file.getBook().getCreatedBy().getId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied to file");
        }

        return toStorageFileResponse(file);
    }

    private StorageFileResponse toStorageFileResponse(BookFile file) {
        return new StorageFileResponse(
                file.getId(),
                file.getBook().getId(),
                file.getFileName(),
                file.getFileFormat(),
                file.getFileSizeBytes(),
                StorageProvider.fromString(file.getStorageProvider()),
                UploadStatus.fromString(file.getStorageStatus()),
                file.getChecksum(),
                file.getUploadedAt(),
                file.getCloudVerifiedAt()
        );
    }

    private String getExtension(String fileName) {
        if (fileName == null || !fileName.contains(".")) return "dat";
        return fileName.substring(fileName.lastIndexOf('.') + 1);
    }

    private String sanitizeFilename(String fileName) {
        if (fileName == null) return "file.bin";
        return fileName.replaceAll("[^a-zA-Z0-9._-]", "_");
    }
}
