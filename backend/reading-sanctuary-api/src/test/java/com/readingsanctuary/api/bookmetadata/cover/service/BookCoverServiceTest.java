package com.readingsanctuary.api.bookmetadata.cover.service;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.extractor.ExtractedBookMetadata;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.book.service.BookMetadataExtractionService;
import com.readingsanctuary.api.book.service.BookStorageService;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.bookfile.service.LocalFileStorageService;

class BookCoverServiceTest {

    private BookRepository bookRepository;
    private LocalFileStorageService storageService;
    private BookFileRepository fileRepository;
    private BookMetadataExtractionService extractionService;
    private BookStorageService bookStorageService;
    private BookCoverService coverService;

    @TempDir
    Path tempDir;

    private final UUID userId = UUID.randomUUID();
    private final UUID bookId = UUID.randomUUID();
    private Book testBook;

    @BeforeEach
    void setUp() {
        bookRepository = mock(BookRepository.class);
        storageService = mock(LocalFileStorageService.class);
        fileRepository = mock(BookFileRepository.class);
        extractionService = mock(BookMetadataExtractionService.class);
        bookStorageService = mock(BookStorageService.class);

        coverService = new BookCoverService(
                bookRepository,
                storageService,
                5242880L,
                fileRepository,
                extractionService,
                bookStorageService
        );

        testBook = new Book();
        ReflectionTestUtils.setField(testBook, "id", bookId);
        testBook.setTitle("The Bone Year");

        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(testBook));
        when(bookRepository.save(any(Book.class))).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void getCover_returnsExistingCoverDirectly() throws IOException {
        testBook.setCoverStorageKey("covers/test.jpg");
        testBook.setCoverContentType("image/jpeg");
        testBook.setCoverFileName("cover.jpg");

        Resource mockResource = new ByteArrayResource(new byte[]{1, 2, 3});
        when(storageService.load("covers/test.jpg")).thenReturn(mockResource);

        BookCoverService.CoverDownload download = coverService.getCover(userId, bookId);

        assertThat(download).isNotNull();
        assertThat(download.resource()).isEqualTo(mockResource);
        assertThat(download.contentType()).isEqualTo("image/jpeg");
    }

    @Test
    void recoverCover_extractsFromEpubAndSavesCover() throws IOException {
        Path dummyEpub = tempDir.resolve("book.epub");
        Files.write(dummyEpub, new byte[]{0x50, 0x4B, 0x03, 0x04});

        BookFile epubFile = new BookFile();
        epubFile.setBook(testBook);
        epubFile.setFileName("book.epub");
        epubFile.setFileFormat("EPUB");
        epubFile.setStorageKey("books/book.epub");

        when(fileRepository.findAllByBook_Id(bookId)).thenReturn(List.of(epubFile));
        when(bookStorageService.getPath("books/book.epub")).thenReturn(dummyEpub);

        // Dummy JPEG: FF D8 FF
        byte[] fakeJpeg = new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 0, 0, 0};
        String base64Cover = "data:image/jpeg;base64," + Base64.getEncoder().encodeToString(fakeJpeg);

        ExtractedBookMetadata metadata = new ExtractedBookMetadata(
                "The Bone Year",
                "Author",
                "Fiction",
                "Description",
                "123",
                100,
                null,
                "en",
                base64Cover
        );

        when(extractionService.extractMetadata(any(File.class), eq("book.epub"), eq("epub")))
                .thenReturn(metadata);
        when(storageService.storeBytes(any(byte[].class), eq("jpg")))
                .thenReturn("covers/new-cover.jpg");

        coverService.recoverCover(userId, bookId);

        assertThat(testBook.getCoverStorageKey()).isEqualTo("covers/new-cover.jpg");
        assertThat(testBook.getCoverContentType()).isEqualTo("image/jpeg");
        assertThat(testBook.getCoverFileName()).isEqualTo("cover.jpg");
        verify(bookRepository).save(testBook);
    }

    @Test
    void getCover_automaticallyRecoversWhenCoverMissing() throws IOException {
        testBook.setCoverStorageKey(null);

        Path dummyPdf = tempDir.resolve("book.pdf");
        Files.write(dummyPdf, new byte[]{0x25, 0x50, 0x44, 0x46});

        BookFile pdfFile = new BookFile();
        pdfFile.setBook(testBook);
        pdfFile.setFileName("book.pdf");
        pdfFile.setFileFormat("PDF");
        pdfFile.setStorageKey("books/book.pdf");

        when(fileRepository.findAllByBook_Id(bookId)).thenReturn(List.of(pdfFile));
        when(bookStorageService.getPath("books/book.pdf")).thenReturn(dummyPdf);

        byte[] fakeJpeg = new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 0, 0, 0};
        String base64Cover = Base64.getEncoder().encodeToString(fakeJpeg);

        ExtractedBookMetadata metadata = new ExtractedBookMetadata(
                "The Bone Year",
                "Author",
                "Fiction",
                "Description",
                "123",
                100,
                null,
                "en",
                base64Cover
        );

        when(extractionService.extractMetadata(any(File.class), eq("book.pdf"), eq("pdf")))
                .thenReturn(metadata);
        when(storageService.storeBytes(any(byte[].class), eq("jpg")))
                .thenReturn("covers/recovered.jpg");

        Resource mockResource = new ByteArrayResource(fakeJpeg);
        when(storageService.load("covers/recovered.jpg")).thenReturn(mockResource);

        BookCoverService.CoverDownload download = coverService.getCover(userId, bookId);

        assertThat(download).isNotNull();
        assertThat(download.resource()).isEqualTo(mockResource);
        assertThat(testBook.getCoverStorageKey()).isEqualTo("covers/recovered.jpg");
        verify(bookRepository).save(testBook);
    }

    @Test
    void recoverCover_throws404WhenNoFilesAttached() {
        when(fileRepository.findAllByBook_Id(bookId)).thenReturn(List.of());

        assertThatThrownBy(() -> coverService.recoverCover(userId, bookId))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("No files found");
    }
}
