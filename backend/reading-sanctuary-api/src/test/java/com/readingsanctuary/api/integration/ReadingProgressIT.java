package com.readingsanctuary.api.integration;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

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
import com.readingsanctuary.api.user.entity.User;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReadingProgressIT {

    @Mock
    private BookReadingPositionRepository positionRepository;

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    private BookReadingPositionService positionService;

    private final UUID userId = UUID.randomUUID();
    private final UUID bookId = UUID.randomUUID();
    private final UUID fileId = UUID.randomUUID();

    private Book book;
    private BookFile pdfFile;

    @BeforeEach
    void setUp() {
        positionService = new BookReadingPositionService(positionRepository, bookRepository, bookFileRepository);

        User user = new User("reader@sanctuary.com", "hash");
        ReflectionTestUtils.setField(user, "id", userId);

        book = new Book();
        ReflectionTestUtils.setField(book, "id", bookId);
        book.setTitle("Designing Data-Intensive Applications");
        book.setCreatedBy(user);
        book.setReadingStatus(ReadingStatus.TO_READ);

        pdfFile = new BookFile();
        ReflectionTestUtils.setField(pdfFile, "id", fileId);
        pdfFile.setBook(book);
        pdfFile.setFileFormat("PDF");
    }

    @Test
    void readingPosition_advancesProgressAndTransitionsStatus() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(pdfFile));

        when(positionRepository.findByBook_IdAndBookFile_Id(bookId, fileId)).thenReturn(Optional.empty());
        when(positionRepository.save(any(BookReadingPosition.class))).thenAnswer(invocation -> {
            BookReadingPosition p = invocation.getArgument(0);
            ReflectionTestUtils.setField(p, "id", UUID.randomUUID());
            return p;
        });

        SaveReadingPositionRequest request = new SaveReadingPositionRequest(
                ReadingLocationType.PDF_PAGE,
                "page=42",
                42,
                550,
                new BigDecimal("7.64")
        );

        ReadingPositionResponse response = positionService.saveOrUpdate(userId, bookId, fileId, request);

        assertThat(response).isNotNull();
        assertThat(response.pageNumber()).isEqualTo(42);
        assertThat(response.totalPages()).isEqualTo(550);
        assertThat(response.progressPercentage()).isEqualByComparingTo("7.64");

        // Verifies status transition from TO_READ to CURRENTLY_READING
        assertThat(book.getReadingStatus()).isEqualTo(ReadingStatus.CURRENTLY_READING);
        assertThat(book.getCurrentPage()).isEqualTo(42);
        assertThat(book.getTotalPages()).isEqualTo(550);
        verify(bookRepository).save(book);
    }
}
