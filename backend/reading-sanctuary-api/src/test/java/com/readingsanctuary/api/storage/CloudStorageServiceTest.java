package com.readingsanctuary.api.storage;

import java.time.Duration;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.storage.config.StorageConfig;
import com.readingsanctuary.api.storage.dto.*;
import com.readingsanctuary.api.storage.enums.StorageProvider;
import com.readingsanctuary.api.storage.enums.UploadStatus;
import com.readingsanctuary.api.storage.service.CloudStorageService;
import com.readingsanctuary.api.storage.service.FileIntegrityService;
import com.readingsanctuary.api.storage.service.StorageProviderFactory;
import com.readingsanctuary.api.storage.service.StorageService;
import com.readingsanctuary.api.user.entity.User;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CloudStorageServiceTest {

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @Mock
    private StorageProviderFactory storageFactory;

    @Mock
    private StorageService storageService;

    private StorageConfig storageConfig;
    private FileIntegrityService integrityService;
    private CloudStorageService cloudStorageService;

    private UUID userId;
    private UUID bookId;
    private Book mockBook;
    private User mockUser;

    @BeforeEach
    void setUp() {
        storageConfig = new StorageConfig();
        storageConfig.setProvider("local");
        integrityService = new FileIntegrityService();

        cloudStorageService = new CloudStorageService(
                bookRepository,
                bookFileRepository,
                storageFactory,
                storageConfig,
                integrityService
        );

        userId = UUID.randomUUID();
        bookId = UUID.randomUUID();

        mockUser = new User("reader@sanctuary.com", "hash");
        ReflectionTestUtils.setField(mockUser, "id", userId);

        mockBook = new Book();
        ReflectionTestUtils.setField(mockBook, "id", bookId);
        mockBook.setCreatedBy(mockUser);
        mockBook.setTitle("Design Patterns");
    }

    @Test
    void requestUploadUrl_success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(mockBook));
        when(storageFactory.getActiveStorageService()).thenReturn(storageService);
        when(storageService.generateUploadUrl(anyString(), anyString(), any(Duration.class)))
                .thenReturn("https://storage.example.com/upload-target");
        when(bookFileRepository.save(any(BookFile.class))).thenAnswer(invocation -> {
            BookFile file = invocation.getArgument(0);
            ReflectionTestUtils.setField(file, "id", UUID.randomUUID());
            return file;
        });

        UploadUrlRequest request = new UploadUrlRequest(
                bookId,
                "design_patterns.pdf",
                "application/pdf",
                1024000L,
                "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        );

        UploadUrlResponse response = cloudStorageService.requestUploadUrl(userId, request);

        assertThat(response).isNotNull();
        assertThat(response.uploadUrl()).isEqualTo("https://storage.example.com/upload-target");
        assertThat(response.fileId()).isNotNull();
        assertThat(response.objectKey()).contains("design_patterns.pdf");
        verify(bookFileRepository).save(any(BookFile.class));
    }

    @Test
    void requestUploadUrl_bookNotFound_throwsException() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.empty());

        UploadUrlRequest request = new UploadUrlRequest(
                bookId,
                "test.epub",
                "application/epub+zip",
                5000L,
                null
        );

        assertThatThrownBy(() -> cloudStorageService.requestUploadUrl(userId, request))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void completeUpload_success() {
        UUID fileId = UUID.randomUUID();
        BookFile file = new BookFile();
        ReflectionTestUtils.setField(file, "id", fileId);
        file.setBook(mockBook);
        file.setFileName("test.pdf");
        file.setStorageKey("users/123/test.pdf");
        file.setStorageProvider("LOCAL");
        file.setStorageStatus(UploadStatus.PENDING_UPLOAD.name());
        file.setChecksum("sha256hash");

        when(bookFileRepository.findById(fileId)).thenReturn(Optional.of(file));
        when(storageFactory.getStorageService(StorageProvider.LOCAL)).thenReturn(storageService);
        when(storageService.exists(file.getStorageKey())).thenReturn(true);
        when(storageService.getObjectSize(file.getStorageKey())).thenReturn(2048L);
        when(bookFileRepository.save(any(BookFile.class))).thenAnswer(i -> i.getArgument(0));

        CompleteUploadRequest request = new CompleteUploadRequest(fileId, "sha256hash", 2048L);
        StorageFileResponse response = cloudStorageService.completeUpload(userId, request);

        assertThat(response).isNotNull();
        assertThat(response.storageStatus()).isEqualTo(UploadStatus.VERIFIED);
        assertThat(response.fileSizeBytes()).isEqualTo(2048L);
    }

    @Test
    void completeUpload_fileNotFoundInStorage_throwsException() {
        UUID fileId = UUID.randomUUID();
        BookFile file = new BookFile();
        ReflectionTestUtils.setField(file, "id", fileId);
        file.setBook(mockBook);
        file.setStorageKey("missing/key");
        file.setStorageProvider("LOCAL");

        when(bookFileRepository.findById(fileId)).thenReturn(Optional.of(file));
        when(storageFactory.getStorageService(StorageProvider.LOCAL)).thenReturn(storageService);
        when(storageService.exists(file.getStorageKey())).thenReturn(false);

        CompleteUploadRequest request = new CompleteUploadRequest(fileId, null, 100L);

        assertThatThrownBy(() -> cloudStorageService.completeUpload(userId, request))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void generateDownloadUrl_success() {
        UUID fileId = UUID.randomUUID();
        BookFile file = new BookFile();
        ReflectionTestUtils.setField(file, "id", fileId);
        file.setBook(mockBook);
        file.setFileName("book.epub");
        file.setStorageKey("users/123/book.epub");
        file.setStorageProvider("LOCAL");
        file.setChecksum("hash123");

        when(bookFileRepository.findById(fileId)).thenReturn(Optional.of(file));
        when(storageFactory.getStorageService(StorageProvider.LOCAL)).thenReturn(storageService);
        when(storageService.generateDownloadUrl(eq(file.getStorageKey()), any(Duration.class)))
                .thenReturn("https://storage.example.com/download/book.epub");

        DownloadUrlResponse response = cloudStorageService.generateDownloadUrl(userId, fileId);

        assertThat(response).isNotNull();
        assertThat(response.downloadUrl()).isEqualTo("https://storage.example.com/download/book.epub");
        assertThat(response.fileName()).isEqualTo("book.epub");
        assertThat(response.checksum()).isEqualTo("hash123");
    }

    @Test
    void deleteFile_success() {
        UUID fileId = UUID.randomUUID();
        BookFile file = new BookFile();
        ReflectionTestUtils.setField(file, "id", fileId);
        file.setBook(mockBook);
        file.setStorageKey("users/123/book.epub");
        file.setStorageProvider("LOCAL");

        when(bookFileRepository.findById(fileId)).thenReturn(Optional.of(file));
        when(storageFactory.getStorageService(StorageProvider.LOCAL)).thenReturn(storageService);

        cloudStorageService.deleteFile(userId, fileId);

        verify(storageService).delete(file.getStorageKey());
        verify(bookFileRepository).delete(file);
    }
}
