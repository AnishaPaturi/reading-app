package com.readingsanctuary.api.book;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import org.mockito.Mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.dto.BookResponse;
import com.readingsanctuary.api.book.dto.BookUploadResponse;
import com.readingsanctuary.api.book.dto.ConfirmBookRequest;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.entity.PendingBookUpload;
import com.readingsanctuary.api.book.extractor.ExtractedBookMetadata;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.book.repository.PendingBookUploadRepository;
import com.readingsanctuary.api.book.service.BookMetadataExtractionService;
import com.readingsanctuary.api.book.service.BookStorageService;
import com.readingsanctuary.api.book.service.BookUploadService;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.bookfile.service.LocalFileStorageService;
import com.readingsanctuary.api.bookmetadata.author.entity.Author;
import com.readingsanctuary.api.bookmetadata.author.repository.AuthorRepository;
import com.readingsanctuary.api.bookmetadata.genre.entity.Genre;
import com.readingsanctuary.api.bookmetadata.genre.repository.GenreRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class BookUploadServiceTest {

    @Mock private UserRepository userRepository;
    @Mock private BookRepository bookRepository;
    @Mock private BookFileRepository fileRepository;
    @Mock private PendingBookUploadRepository pendingRepository;
    @Mock private AuthorRepository authorRepository;
    @Mock private GenreRepository genreRepository;
    @Mock private BookStorageService storageService;
    @Mock private BookMetadataExtractionService extractionService;
    @Mock private LocalFileStorageService localStorageService;

    private BookUploadService uploadService;
    private UUID userId;
    private User testUser;

    @BeforeEach
    void setUp() {
        uploadService = new BookUploadService(
                userRepository,
                bookRepository,
                fileRepository,
                pendingRepository,
                authorRepository,
                genreRepository,
                storageService,
                extractionService,
                localStorageService,
                null
        );

        userId = UUID.randomUUID();
        testUser = new User("reader@sanctuary.com", "hash123");
        testUser.setId(userId);
    }

    @Test
    void uploadAndExtract_UnsupportedFormat_ThrowsBadRequest() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "script.exe", "application/octet-stream", new byte[]{ 0x4D, 0x5A, 0x00, 0x00 }
        );

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));

        assertThatThrownBy(() -> uploadService.uploadAndExtract(file, userId))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Unsupported book format");
    }

    @Test
    void uploadAndExtract_InvalidSignature_ThrowsBadRequest() {
        // PDF extension but invalid magic bytes
        MockMultipartFile file = new MockMultipartFile(
                "file", "fake.pdf", "application/pdf", new byte[]{ 0x00, 0x01, 0x02, 0x03 }
        );

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));

        assertThatThrownBy(() -> uploadService.uploadAndExtract(file, userId))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("File signature does not match PDF format");
    }

    @Test
    void uploadAndExtract_ValidPdf_SavesPendingAndReturnsResponse() throws IOException {
        byte[] pdfBytes = new byte[]{ 0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34 };
        MockMultipartFile file = new MockMultipartFile(
                "file", "novel.pdf", "application/pdf", pdfBytes
        );

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(storageService.storePending(any(), eq("pdf"))).thenReturn("pending/uuid.pdf");
        when(storageService.getPath("pending/uuid.pdf")).thenReturn(Path.of("temp.pdf"));
        when(extractionService.extractMetadata(any(), eq("novel.pdf"), eq("pdf"))).thenReturn(
                new ExtractedBookMetadata("Extracted Novel", "Jane Doe", "Fiction", "Desc", null, 250, null, "en", null)
        );

        when(pendingRepository.save(any(PendingBookUpload.class))).thenAnswer(invocation -> {
            PendingBookUpload p = invocation.getArgument(0);
            p.setId(UUID.randomUUID());
            return p;
        });

        BookUploadResponse response = uploadService.uploadAndExtract(file, userId);

        assertThat(response.title()).isEqualTo("Extracted Novel");
        assertThat(response.author()).isEqualTo("Jane Doe");
        assertThat(response.format()).isEqualTo("PDF");
        verify(pendingRepository).save(any(PendingBookUpload.class));
    }

    @Test
    void confirmBook_ValidRequest_CreatesBookAndPromotesFile() throws IOException {
        UUID uploadId = UUID.randomUUID();
        PendingBookUpload pending = new PendingBookUpload();
        pending.setId(uploadId);
        pending.setUser(testUser);
        pending.setFileName("book.epub");
        pending.setFileFormat("EPUB");
        pending.setStorageKey("pending/key.epub");
        pending.setFileSizeBytes(1024L);
        pending.setChecksum("sha256-hash");
        pending.setExpiresAt(OffsetDateTime.now().plusHours(2));

        when(pendingRepository.findByIdAndUser_Id(uploadId, userId)).thenReturn(Optional.of(pending));
        when(storageService.promoteToPermanent("pending/key.epub")).thenReturn("books/key.epub");
        when(authorRepository.findByNameIgnoreCase("Famous Author")).thenReturn(Optional.empty());
        when(authorRepository.save(any(Author.class))).thenAnswer(inv -> inv.getArgument(0));
        when(genreRepository.findByNameIgnoreCase("Fantasy")).thenReturn(Optional.empty());
        when(genreRepository.save(any(Genre.class))).thenAnswer(inv -> inv.getArgument(0));

        when(bookRepository.save(any(Book.class))).thenAnswer(inv -> {
            Book b = inv.getArgument(0);
            return b;
        });

        ConfirmBookRequest request = new ConfirmBookRequest(
                uploadId.toString(),
                "Confirmed Book Title",
                "Famous Author",
                "Fantasy",
                "A captivating tale",
                350,
                "WANT_TO_READ",
                null
        );

        BookResponse response = uploadService.confirmBook(request, userId);

        assertThat(response.title()).isEqualTo("Confirmed Book Title");
        verify(fileRepository).save(any(BookFile.class));
        verify(pendingRepository).delete(pending);
    }
}
