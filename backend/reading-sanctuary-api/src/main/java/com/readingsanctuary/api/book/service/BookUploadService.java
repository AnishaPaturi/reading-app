package com.readingsanctuary.api.book.service;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.dto.BookResponse;
import com.readingsanctuary.api.book.dto.BookUploadResponse;
import com.readingsanctuary.api.book.dto.ConfirmBookRequest;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.entity.PendingBookUpload;
import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.book.extractor.ExtractedBookMetadata;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.book.repository.PendingBookUploadRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.bookfile.service.LocalFileStorageService;
import com.readingsanctuary.api.bookmetadata.author.entity.Author;
import com.readingsanctuary.api.bookmetadata.author.repository.AuthorRepository;
import com.readingsanctuary.api.bookmetadata.genre.entity.Genre;
import com.readingsanctuary.api.bookmetadata.genre.repository.GenreRepository;
import com.readingsanctuary.api.sync.service.SyncChangePublisher;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
public class BookUploadService {

    private static final Logger log = LoggerFactory.getLogger(BookUploadService.class);

    private static final Set<String> SUPPORTED_FORMATS = Set.of("pdf", "epub", "mp3", "m4b");
    private static final long MAX_FILE_SIZE = 100L * 1024 * 1024; // 100 MB

    private final UserRepository userRepository;
    private final BookRepository bookRepository;
    private final BookFileRepository fileRepository;
    private final PendingBookUploadRepository pendingRepository;
    private final AuthorRepository authorRepository;
    private final GenreRepository genreRepository;
    private final BookStorageService storageService;
    private final BookMetadataExtractionService extractionService;
    private final LocalFileStorageService localStorageService;
    private final SyncChangePublisher changePublisher;

    @Autowired
    public BookUploadService(
            UserRepository userRepository,
            BookRepository bookRepository,
            BookFileRepository fileRepository,
            PendingBookUploadRepository pendingRepository,
            AuthorRepository authorRepository,
            GenreRepository genreRepository,
            BookStorageService storageService,
            BookMetadataExtractionService extractionService,
            LocalFileStorageService localStorageService,
            @Autowired(required = false) SyncChangePublisher changePublisher) {

        this.userRepository = userRepository;
        this.bookRepository = bookRepository;
        this.fileRepository = fileRepository;
        this.pendingRepository = pendingRepository;
        this.authorRepository = authorRepository;
        this.genreRepository = genreRepository;
        this.storageService = storageService;
        this.extractionService = extractionService;
        this.localStorageService = localStorageService;
        this.changePublisher = changePublisher;
    }

    /**
     * Stage 1: Upload and extract metadata into a temporary session.
     */
    @Transactional
    public BookUploadResponse uploadAndExtract(MultipartFile file, UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File is required and cannot be empty");
        }

        if (file.getSize() > MAX_FILE_SIZE) {
            throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE, "File size exceeds the 100 MB limit");
        }

        String originalName = file.getOriginalFilename();
        if (originalName == null || originalName.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid file name");
        }

        String safeName = originalName.replace("\\", "/");
        safeName = safeName.substring(safeName.lastIndexOf('/') + 1);

        int dot = safeName.lastIndexOf('.');
        if (dot <= 0 || dot >= safeName.length() - 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Valid file extension is required");
        }

        String extension = safeName.substring(dot + 1).toLowerCase(Locale.ROOT);
        if (!SUPPORTED_FORMATS.contains(extension)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Unsupported book format: ." + extension + ". Supported formats are PDF, EPUB, MP3, and M4B."
            );
        }

        // Validate actual file signature (magic bytes) to prevent renamed executables
        validateFileSignature(file, extension);

        String pendingKey = null;
        try {
            String checksum = calculateChecksum(file);

            // Store file into pending storage
            pendingKey = storageService.storePending(file, extension);
            Path filePath = storageService.getPath(pendingKey);

            // Extract metadata using specialized extractor
            ExtractedBookMetadata metadata = extractionService.extractMetadata(
                    filePath.toFile(),
                    safeName,
                    extension
            );

            // Create pending upload record
            PendingBookUpload pending = new PendingBookUpload();
            pending.setUser(user);
            pending.setFileName(safeName);
            pending.setFileFormat(extension.toUpperCase(Locale.ROOT));
            pending.setStorageKey(pendingKey);
            pending.setFileSizeBytes(file.getSize());
            pending.setChecksum(checksum);
            pending.setTitle(metadata.title());
            pending.setAuthor(metadata.author());
            pending.setGenre(metadata.genre());
            pending.setDescription(metadata.description());
            pending.setIsbn(metadata.isbn());
            pending.setPages(metadata.pages());
            pending.setDurationSeconds(metadata.durationSeconds());
            pending.setLanguage(metadata.language() != null ? metadata.language() : "en");
            pending.setCoverBase64(metadata.coverBase64());
            pending.setCreatedAt(OffsetDateTime.now());
            pending.setExpiresAt(OffsetDateTime.now().plusHours(24));

            PendingBookUpload saved = pendingRepository.save(pending);

            return new BookUploadResponse(
                    saved.getId().toString(),
                    saved.getFileName(),
                    saved.getFileFormat(),
                    saved.getTitle(),
                    saved.getAuthor(),
                    saved.getGenre(),
                    saved.getDescription(),
                    saved.getIsbn(),
                    saved.getPages(),
                    saved.getDurationSeconds(),
                    saved.getLanguage(),
                    saved.getCoverBase64()
            );

        } catch (IOException | NoSuchAlgorithmException e) {
            if (pendingKey != null) {
                storageService.delete(pendingKey);
            }
            log.error("Failed to process uploaded book file: {}", e.getMessage(), e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to process uploaded book file: " + e.getMessage());
        }
    }

    /**
     * Stage 2: Confirm edited details and persist permanent book & book_file.
     */
    @Transactional
    public BookResponse confirmBook(ConfirmBookRequest request, UUID userId) {
        UUID uploadId;
        try {
            uploadId = UUID.fromString(request.uploadId());
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid upload ID format");
        }

        PendingBookUpload pending = pendingRepository.findByIdAndUser_Id(uploadId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Upload session not found or does not belong to you"));

        if (pending.getExpiresAt().isBefore(OffsetDateTime.now())) {
            storageService.delete(pending.getStorageKey());
            pendingRepository.delete(pending);
            throw new ResponseStatusException(HttpStatus.GONE, "Upload session has expired. Please re-upload your book.");
        }

        User user = pending.getUser();
        Book book;

        if (request.existingBookId() != null) {
            // Attach to an existing book belonging to this user
            book = bookRepository.findByIdAndCreatedBy_Id(request.existingBookId(), userId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Existing book not found"));
        } else {
            // Create a brand new Book record
            book = new Book();
            book.setCreatedBy(user);
            book.setTitle(request.title().trim());
            book.setDescription(request.description() != null ? request.description().trim() : pending.getDescription());
            book.setLanguage(pending.getLanguage() != null ? pending.getLanguage() : "en");
            book.setIsbn(pending.getIsbn());

            if (request.pages() != null && request.pages() > 0) {
                book.setTotalPages(request.pages());
            } else if (pending.getPages() != null && pending.getPages() > 0) {
                book.setTotalPages(pending.getPages());
            }

            book.setReadingStatus(mapReadingStatus(request.readingStatus()));

            // Link author if present
            String authorName = request.author() != null && !request.author().isBlank()
                    ? request.author().trim()
                    : pending.getAuthor();

            if (authorName != null && !authorName.isBlank()) {
                book.setPublisher(authorName);
                Author author = authorRepository.findByNameIgnoreCase(authorName)
                        .orElseGet(() -> {
                            Author a = new Author();
                            a.setName(authorName);
                            return authorRepository.save(a);
                        });
                book.getAuthors().add(author);
            }

            // Link genre if present
            String genreName = request.genre() != null && !request.genre().isBlank()
                    ? request.genre().trim()
                    : pending.getGenre();

            if (genreName != null && !genreName.isBlank()) {
                Genre genre = genreRepository.findByNameIgnoreCase(genreName)
                        .orElseGet(() -> {
                            Genre g = new Genre();
                            g.setName(genreName);
                            return genreRepository.save(g);
                        });
                book.getGenres().add(genre);
            }

            // Process cover if extracted
            if (pending.getCoverBase64() != null && !pending.getCoverBase64().isBlank()) {
                saveExtractedCover(book, pending.getCoverBase64());
            }

            book = bookRepository.save(book);

            if (changePublisher != null) {
                changePublisher.publishCreate(userId, "BOOK", book.getId().toString(), 1L, toBookResponse(book));
            }
        }

        // Promote pending file to permanent storage
        String permanentKey;
        try {
            permanentKey = storageService.promoteToPermanent(pending.getStorageKey());
        } catch (IOException e) {
            log.error("Failed to move pending file to permanent storage: {}", e.getMessage(), e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to finalize book storage");
        }

        // Create BookFile attachment record
        BookFile bookFile = new BookFile();
        bookFile.setBook(book);
        bookFile.setFileName(pending.getFileName());
        bookFile.setFileFormat(pending.getFileFormat());
        bookFile.setStorageKey(permanentKey);
        bookFile.setFileSizeBytes(pending.getFileSizeBytes());
        bookFile.setChecksum(pending.getChecksum());
        bookFile.setDurationSeconds(pending.getDurationSeconds() != null ? Long.valueOf(pending.getDurationSeconds()) : null);
        bookFile.setStorageProvider("LOCAL");
        bookFile.setStorageStatus("LOCAL");

        fileRepository.save(bookFile);

        // Delete pending upload record
        pendingRepository.delete(pending);

        return toBookResponse(book);
    }

    private void saveExtractedCover(Book book, String coverBase64) {
        try {
            String cleanData = coverBase64;
            String extension = "jpg";
            String contentType = "image/jpeg";

            if (coverBase64.startsWith("data:")) {
                int comma = coverBase64.indexOf(',');
                if (comma > 0) {
                    String meta = coverBase64.substring(5, comma);
                    cleanData = coverBase64.substring(comma + 1);
                    if (meta.contains("image/png")) {
                        extension = "png";
                        contentType = "image/png";
                    } else if (meta.contains("image/webp")) {
                        extension = "webp";
                        contentType = "image/webp";
                    }
                }
            }

            byte[] bytes = Base64.getDecoder().decode(cleanData.trim());
            if (bytes.length > 0 && bytes.length <= 10 * 1024 * 1024) {
                String coverStorageKey = localStorageService.storeBytes(bytes, extension);
                book.setCoverStorageKey(coverStorageKey);
                book.setCoverFileName("cover." + extension);
                book.setCoverContentType(contentType);
                book.setCoverUpdatedAt(OffsetDateTime.now());
            }
        } catch (Exception e) {
            log.warn("Could not save extracted cover image: {}", e.getMessage());
        }
    }

    private void validateFileSignature(MultipartFile file, String extension) {
        try (InputStream in = file.getInputStream()) {
            byte[] header = new byte[12];
            int read = in.read(header);
            if (read < 4) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File is corrupted or too small");
            }

            switch (extension) {
                case "pdf" -> {
                    // %PDF
                    if (header[0] != 0x25 || header[1] != 0x50 || header[2] != 0x44 || header[3] != 0x46) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File signature does not match PDF format");
                    }
                }
                case "epub" -> {
                    // PK\x03\x04
                    if (header[0] != 0x50 || header[1] != 0x4B || header[2] != 0x03 || header[3] != 0x04) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File signature does not match EPUB format");
                    }
                }
                case "mp3" -> {
                    // ID3 or MPEG frame sync (0xFF)
                    boolean isId3 = header[0] == 0x49 && header[1] == 0x44 && header[2] == 0x33;
                    boolean isMpeg = (header[0] & 0xFF) == 0xFF && ((header[1] & 0xE0) == 0xE0);
                    if (!isId3 && !isMpeg) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File signature does not match MP3 format");
                    }
                }
                case "m4b" -> {
                    // MP4 container has 'ftyp' at offset 4
                    if (read >= 8) {
                        boolean isFtyp = header[4] == 'f' && header[5] == 't' && header[6] == 'y' && header[7] == 'p';
                        if (!isFtyp) {
                            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File signature does not match M4B/MP4 format");
                        }
                    }
                }
            }
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Could not verify file integrity");
        }
    }

    private String calculateChecksum(MultipartFile file) throws NoSuchAlgorithmException, IOException {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream in = file.getInputStream()) {
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) != -1) {
                digest.update(buf, 0, n);
            }
        }
        return HexFormat.of().formatHex(digest.digest());
    }

    private ReadingStatus mapReadingStatus(String status) {
        if (status == null || status.isBlank()) return ReadingStatus.TO_READ;
        String s = status.toUpperCase(Locale.ROOT);
        if (s.contains("CURRENTLY") || s.contains("READING")) return ReadingStatus.CURRENTLY_READING;
        if (s.contains("COMPLETED") || s.contains("DONE")) return ReadingStatus.COMPLETED;
        if (s.contains("DNF")) return ReadingStatus.DNF;
        return ReadingStatus.TO_READ;
    }

    private BookResponse toBookResponse(Book book) {
        return new BookResponse(
                book.getId(),
                book.getTitle(),
                book.getDescription(),
                book.getLanguage(),
                book.getPublisher(),
                book.getPublicationDate(),
                book.getIsbn(),
                book.getCreatedAt(),
                book.getUpdatedAt()
        );
    }

    /**
     * Scheduled cleanup job: deletes expired pending records and files older than 24 hours.
     */
    @Scheduled(fixedDelay = 3600000)
    public void cleanupExpiredUploads() {
        try {
            OffsetDateTime now = OffsetDateTime.now();
            List<PendingBookUpload> expired = pendingRepository.findAllByExpiresAtBefore(now);
            for (PendingBookUpload p : expired) {
                storageService.delete(p.getStorageKey());
                pendingRepository.delete(p);
            }
            // Clean unreferenced files in pending/ older than 24 hours
            storageService.cleanExpiredPendingFiles(24L * 60 * 60 * 1000);
        } catch (Exception e) {
            log.error("Error running pending uploads cleanup: {}", e.getMessage());
        }
    }
}
