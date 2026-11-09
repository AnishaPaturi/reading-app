package com.readingsanctuary.api.text;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.bookfile.service.LocalFileStorageService;
import com.readingsanctuary.api.text.service.DocumentTextExtractionService;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DocumentTextExtractionServiceTest {

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @Mock
    private LocalFileStorageService storageService;

    @InjectMocks
    private DocumentTextExtractionService textExtractionService;

    private UUID userId;
    private UUID bookId;
    private UUID fileId;
    private Book book;
    private BookFile mp3File;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        bookId = UUID.randomUUID();
        fileId = UUID.randomUUID();

        book = new Book();
        ReflectionTestUtils.setField(book, "id", bookId);
        book.setTitle("Test Title");

        mp3File = new BookFile();
        ReflectionTestUtils.setField(mp3File, "id", fileId);
        mp3File.setBook(book);
        mp3File.setFileFormat("MP3");
    }

    @Test
    void splitIntoChunks_SplitsParagraphsProperly() {
        String sampleText = "First paragraph here.\n\nSecond paragraph here.\n\nThird paragraph.";
        List<String> chunks = textExtractionService.splitIntoChunks(sampleText, 25);

        assertThat(chunks).isNotEmpty();
        assertThat(chunks).contains("First paragraph here.", "Second paragraph here.", "Third paragraph.");
    }

    @Test
    void extractText_InvalidFormat_ThrowsBadRequest() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(mp3File));

        assertThatThrownBy(() -> textExtractionService.extractText(userId, bookId, fileId, 1))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void extractText_CrossUser_ThrowsNotFound() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> textExtractionService.extractText(userId, bookId, fileId, 1))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }
}
