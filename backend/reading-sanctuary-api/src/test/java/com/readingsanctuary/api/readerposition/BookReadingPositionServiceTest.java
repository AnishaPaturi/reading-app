package com.readingsanctuary.api.readerposition;

import java.math.BigDecimal;
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
import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.common.enums.ReadingLocationType;
import com.readingsanctuary.api.readerposition.dto.ReadingPositionResponse;
import com.readingsanctuary.api.readerposition.dto.SaveReadingPositionRequest;
import com.readingsanctuary.api.readerposition.entity.BookReadingPosition;
import com.readingsanctuary.api.readerposition.repository.BookReadingPositionRepository;
import com.readingsanctuary.api.readerposition.service.BookReadingPositionService;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookReadingPositionServiceTest {

    @Mock
    private BookReadingPositionRepository positionRepository;

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @InjectMocks
    private BookReadingPositionService positionService;

    private UUID userId;
    private UUID bookId;
    private UUID fileId;
    private Book book;
    private BookFile pdfFile;
    private BookFile epubFile;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        bookId = UUID.randomUUID();
        fileId = UUID.randomUUID();

        book = new Book();
        ReflectionTestUtils.setField(book, "id", bookId);
        book.setReadingStatus(ReadingStatus.TO_READ);

        pdfFile = new BookFile();
        ReflectionTestUtils.setField(pdfFile, "id", fileId);
        pdfFile.setBook(book);
        pdfFile.setFileFormat("PDF");

        epubFile = new BookFile();
        ReflectionTestUtils.setField(epubFile, "id", fileId);
        epubFile.setBook(book);
        epubFile.setFileFormat("EPUB");
    }

    @Test
    void saveOrUpdate_CreatesNewPosition_UpdatesBookStatus() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(pdfFile));
        when(positionRepository.findByBook_IdAndBookFile_Id(bookId, fileId)).thenReturn(Optional.empty());
        when(positionRepository.save(any(BookReadingPosition.class))).thenAnswer(invocation -> {
            BookReadingPosition p = invocation.getArgument(0);
            ReflectionTestUtils.setField(p, "id", UUID.randomUUID());
            return p;
        });

        SaveReadingPositionRequest request = new SaveReadingPositionRequest(
                ReadingLocationType.PDF_PAGE, "page=15", 15, 300, new BigDecimal("5.00"));

        ReadingPositionResponse response = positionService.saveOrUpdate(userId, bookId, fileId, request);

        assertThat(response.bookId()).isEqualTo(bookId);
        assertThat(response.bookFileId()).isEqualTo(fileId);
        assertThat(response.pageNumber()).isEqualTo(15);
        assertThat(response.totalPages()).isEqualTo(300);
        assertThat(response.progressPercentage()).isEqualTo(new BigDecimal("5.00"));

        assertThat(book.getReadingStatus()).isEqualTo(ReadingStatus.CURRENTLY_READING);
        assertThat(book.getCurrentPage()).isEqualTo(15);
        assertThat(book.getTotalPages()).isEqualTo(300);
        verify(bookRepository).save(book);
    }

    @Test
    void saveOrUpdate_PreservesCompletedBookStatus() {
        book.setReadingStatus(ReadingStatus.COMPLETED);

        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(pdfFile));
        when(positionRepository.findByBook_IdAndBookFile_Id(bookId, fileId)).thenReturn(Optional.empty());
        when(positionRepository.save(any(BookReadingPosition.class))).thenAnswer(invocation -> invocation.getArgument(0));

        SaveReadingPositionRequest request = new SaveReadingPositionRequest(
                ReadingLocationType.PDF_PAGE, "page=10", 10, 300, new BigDecimal("3.33"));

        positionService.saveOrUpdate(userId, bookId, fileId, request);

        assertThat(book.getReadingStatus()).isEqualTo(ReadingStatus.COMPLETED);
    }

    @Test
    void saveOrUpdate_FormatMismatch_ThrowsBadRequest() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(epubFile));

        SaveReadingPositionRequest request = new SaveReadingPositionRequest(
                ReadingLocationType.PDF_PAGE, "page=15", 15, 300, new BigDecimal("5.00"));

        assertThatThrownBy(() -> positionService.saveOrUpdate(userId, bookId, fileId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void getPosition_ReturnsEmpty_WhenNotPresent() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(pdfFile));
        when(positionRepository.findByBook_IdAndBookFile_Id(bookId, fileId)).thenReturn(Optional.empty());

        Optional<ReadingPositionResponse> pos = positionService.getPosition(userId, bookId, fileId);

        assertThat(pos).isEmpty();
    }

    @Test
    void resetPosition_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(pdfFile));

        positionService.resetPosition(userId, bookId, fileId);

        verify(positionRepository).deleteByBook_IdAndBookFile_Id(bookId, fileId);
    }
}
