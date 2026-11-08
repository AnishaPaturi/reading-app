package com.readingsanctuary.api.highlight;

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
import com.readingsanctuary.api.common.enums.HighlightColor;
import com.readingsanctuary.api.common.enums.ReadingLocationType;
import com.readingsanctuary.api.highlight.dto.CreateHighlightRequest;
import com.readingsanctuary.api.highlight.dto.HighlightResponse;
import com.readingsanctuary.api.highlight.dto.UpdateHighlightRequest;
import com.readingsanctuary.api.highlight.entity.BookHighlight;
import com.readingsanctuary.api.highlight.repository.BookHighlightRepository;
import com.readingsanctuary.api.highlight.service.HighlightService;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class HighlightServiceTest {

    @Mock
    private BookHighlightRepository highlightRepository;

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @InjectMocks
    private HighlightService highlightService;

    private UUID userId;
    private UUID otherUserId;
    private UUID bookId;
    private UUID fileId;
    private Book book;
    private BookFile pdfFile;
    private BookFile docxFile;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        otherUserId = UUID.randomUUID();
        bookId = UUID.randomUUID();
        fileId = UUID.randomUUID();

        book = new Book();
        ReflectionTestUtils.setField(book, "id", bookId);

        pdfFile = new BookFile();
        ReflectionTestUtils.setField(pdfFile, "id", fileId);
        pdfFile.setBook(book);
        pdfFile.setFileFormat("PDF");

        docxFile = new BookFile();
        ReflectionTestUtils.setField(docxFile, "id", fileId);
        docxFile.setBook(book);
        docxFile.setFileFormat("DOCX");
    }

    @Test
    void createHighlight_Success_DefaultColor() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(pdfFile));
        when(highlightRepository.save(any(BookHighlight.class))).thenAnswer(invocation -> {
            BookHighlight h = invocation.getArgument(0);
            ReflectionTestUtils.setField(h, "id", UUID.randomUUID());
            return h;
        });

        CreateHighlightRequest request = new CreateHighlightRequest(
                fileId, "Important quote", ReadingLocationType.PDF_PAGE, "page=15;offset=10", "page=15;offset=50",
                15, null, "My note");

        HighlightResponse response = highlightService.create(userId, bookId, request);

        assertThat(response.bookId()).isEqualTo(bookId);
        assertThat(response.bookFileId()).isEqualTo(fileId);
        assertThat(response.selectedText()).isEqualTo("Important quote");
        assertThat(response.color()).isEqualTo(HighlightColor.YELLOW);
        assertThat(response.annotationNote()).isEqualTo("My note");
        assertThat(response.pageNumber()).isEqualTo(15);
    }

    @Test
    void createHighlight_FormatMismatch_ThrowsBadRequest() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(docxFile));

        CreateHighlightRequest request = new CreateHighlightRequest(
                fileId, "Important quote", ReadingLocationType.PDF_PAGE, "page=15;offset=10", "page=15;offset=50",
                15, HighlightColor.BLUE, null);

        assertThatThrownBy(() -> highlightService.create(userId, bookId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void createHighlight_UnownedBook_ThrowsNotFound() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, otherUserId)).thenReturn(Optional.empty());

        CreateHighlightRequest request = new CreateHighlightRequest(
                fileId, "Important quote", ReadingLocationType.PDF_PAGE, "page=15;offset=10", "page=15;offset=50",
                15, HighlightColor.GREEN, null);

        assertThatThrownBy(() -> highlightService.create(otherUserId, bookId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    void getAllHighlights_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        BookHighlight h = new BookHighlight();
        ReflectionTestUtils.setField(h, "id", UUID.randomUUID());
        h.setBook(book);
        h.setBookFile(pdfFile);
        h.setSelectedText("Text");
        h.setLocationType(ReadingLocationType.PDF_PAGE);
        h.setStartLocation("start");
        h.setEndLocation("end");
        h.setColor(HighlightColor.PINK);

        when(highlightRepository.findAllByBook_IdOrderByCreatedAtDesc(bookId)).thenReturn(List.of(h));

        List<HighlightResponse> list = highlightService.getAll(userId, bookId);

        assertThat(list).hasSize(1);
        assertThat(list.get(0).selectedText()).isEqualTo("Text");
        assertThat(list.get(0).color()).isEqualTo(HighlightColor.PINK);
    }

    @Test
    void updateHighlight_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        UUID highlightId = UUID.randomUUID();
        BookHighlight h = new BookHighlight();
        ReflectionTestUtils.setField(h, "id", highlightId);
        h.setBook(book);
        h.setBookFile(pdfFile);
        h.setSelectedText("Text");
        h.setLocationType(ReadingLocationType.PDF_PAGE);
        h.setStartLocation("start");
        h.setEndLocation("end");
        h.setColor(HighlightColor.YELLOW);

        when(highlightRepository.findByIdAndBook_Id(highlightId, bookId)).thenReturn(Optional.of(h));
        when(highlightRepository.save(any(BookHighlight.class))).thenAnswer(inv -> inv.getArgument(0));

        UpdateHighlightRequest updateRequest = new UpdateHighlightRequest(HighlightColor.PURPLE, "Updated note");
        HighlightResponse updated = highlightService.update(userId, bookId, highlightId, updateRequest);

        assertThat(updated.color()).isEqualTo(HighlightColor.PURPLE);
        assertThat(updated.annotationNote()).isEqualTo("Updated note");
    }

    @Test
    void deleteHighlight_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        UUID highlightId = UUID.randomUUID();
        BookHighlight h = new BookHighlight();
        h.setBook(book);
        h.setBookFile(pdfFile);

        when(highlightRepository.findByIdAndBook_Id(highlightId, bookId)).thenReturn(Optional.of(h));

        highlightService.delete(userId, bookId, highlightId);

        verify(highlightRepository).delete(h);
    }

    @Test
    void deleteHighlight_NotFound_ThrowsNotFound() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        UUID highlightId = UUID.randomUUID();
        when(highlightRepository.findByIdAndBook_Id(highlightId, bookId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> highlightService.delete(userId, bookId, highlightId))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }
}
