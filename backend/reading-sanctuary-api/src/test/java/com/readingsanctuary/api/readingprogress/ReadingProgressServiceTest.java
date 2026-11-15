package com.readingsanctuary.api.readingprogress;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
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
import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.readingprogress.dto.ReadingProgressRequest;
import com.readingsanctuary.api.readingprogress.dto.ReadingProgressResponse;
import com.readingsanctuary.api.readingprogress.entity.ReadingProgress;
import com.readingsanctuary.api.readingprogress.repository.ReadingProgressRepository;
import com.readingsanctuary.api.readingprogress.service.ReadingProgressService;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReadingProgressServiceTest {

    @Mock
    private ReadingProgressRepository progressRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @Mock
    private BookRepository bookRepository;

    @Mock
    private UserRepository userRepository;

    private ReadingProgressService progressService;

    private final UUID userId = UUID.randomUUID();
    private final UUID bookId = UUID.randomUUID();
    private final UUID fileId = UUID.randomUUID();

    private User user;
    private Book book;
    private BookFile bookFile;

    @BeforeEach
    void setUp() {
        progressService = new ReadingProgressService(
                progressRepository, bookFileRepository, bookRepository, userRepository);

        user = new User("user@test.com", "hash");
        ReflectionTestUtils.setField(user, "id", userId);

        book = new Book();
        ReflectionTestUtils.setField(book, "id", bookId);
        book.setCreatedBy(user);
        book.setReadingStatus(ReadingStatus.TO_READ);

        bookFile = new BookFile();
        ReflectionTestUtils.setField(bookFile, "id", fileId);
        bookFile.setBook(book);
        bookFile.setFileFormat("PDF");
    }

    @Test
    void saveProgress_createsNewRecordAndUpdatesBook() {
        when(bookFileRepository.findById(fileId)).thenReturn(Optional.of(bookFile));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(progressRepository.findByUserIdAndBookFileId(userId, fileId)).thenReturn(Optional.empty());
        when(progressRepository.save(any(ReadingProgress.class))).thenAnswer(inv -> inv.getArgument(0));

        ReadingProgressRequest req = new ReadingProgressRequest(
                "PDF",
                182,
                363,
                null,
                null,
                null,
                null,
                BigDecimal.valueOf(50.138),
                "{\"scrollOffset\":0}",
                OffsetDateTime.now()
        );

        ReadingProgressResponse res = progressService.saveProgress(userId, fileId, req);

        assertThat(res).isNotNull();
        assertThat(res.currentPage()).isEqualTo(182);
        assertThat(res.totalPages()).isEqualTo(363);
        assertThat(res.format()).isEqualTo("PDF");
        assertThat(book.getReadingStatus()).isEqualTo(ReadingStatus.CURRENTLY_READING);
        assertThat(book.getCurrentPage()).isEqualTo(182);
        assertThat(book.getTotalPages()).isEqualTo(363);

        verify(progressRepository).save(any(ReadingProgress.class));
        verify(bookRepository).save(book);
    }

    @Test
    void saveProgress_updatesExistingRecord() {
        ReadingProgress existing = new ReadingProgress();
        existing.setUser(user);
        existing.setBookFile(bookFile);
        existing.setFormat("PDF");
        existing.setCurrentPage(10);
        existing.setTotalPages(100);

        when(bookFileRepository.findById(fileId)).thenReturn(Optional.of(bookFile));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(progressRepository.findByUserIdAndBookFileId(userId, fileId)).thenReturn(Optional.of(existing));
        when(progressRepository.save(any(ReadingProgress.class))).thenAnswer(inv -> inv.getArgument(0));

        ReadingProgressRequest req = new ReadingProgressRequest(
                "PDF",
                50,
                100,
                null,
                null,
                null,
                null,
                BigDecimal.valueOf(50.0),
                "{}",
                OffsetDateTime.now()
        );

        ReadingProgressResponse res = progressService.saveProgress(userId, fileId, req);

        assertThat(res.currentPage()).isEqualTo(50);
        assertThat(existing.getCurrentPage()).isEqualTo(50);
        verify(progressRepository).save(existing);
    }

    @Test
    void getProgress_returnsProgressForOwner() {
        ReadingProgress existing = new ReadingProgress();
        existing.setUser(user);
        existing.setBookFile(bookFile);
        existing.setFormat("PDF");
        existing.setCurrentPage(182);
        existing.setTotalPages(363);

        when(bookFileRepository.findById(fileId)).thenReturn(Optional.of(bookFile));
        when(progressRepository.findByUserIdAndBookFileId(userId, fileId)).thenReturn(Optional.of(existing));

        Optional<ReadingProgressResponse> res = progressService.getProgress(userId, fileId);

        assertThat(res).isPresent();
        assertThat(res.get().currentPage()).isEqualTo(182);
    }

    @Test
    void getProgress_deniesAccessToNonOwner() {
        UUID otherUser = UUID.randomUUID();
        when(bookFileRepository.findById(fileId)).thenReturn(Optional.of(bookFile));

        assertThatThrownBy(() -> progressService.getProgress(otherUser, fileId))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void resetProgress_deletesRecord() {
        when(bookFileRepository.findById(fileId)).thenReturn(Optional.of(bookFile));

        progressService.resetProgress(userId, fileId);

        verify(progressRepository).deleteByUserIdAndBookFileId(userId, fileId);
    }
}
