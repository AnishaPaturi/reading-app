package com.readingsanctuary.api.security;

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
import com.readingsanctuary.api.book.service.BookService;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.bookmark.dto.CreateBookmarkRequest;
import com.readingsanctuary.api.bookmark.repository.BookmarkRepository;
import com.readingsanctuary.api.bookmark.service.BookmarkService;
import com.readingsanctuary.api.common.enums.ReadingLocationType;
import com.readingsanctuary.api.note.dto.CreateBookNoteRequest;
import com.readingsanctuary.api.note.repository.BookNoteRepository;
import com.readingsanctuary.api.note.service.BookNoteService;
import com.readingsanctuary.api.readerposition.dto.SaveReadingPositionRequest;
import com.readingsanctuary.api.readerposition.repository.BookReadingPositionRepository;
import com.readingsanctuary.api.readerposition.service.BookReadingPositionService;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserDataIsolationTest {

    @Mock
    private BookRepository bookRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @Mock
    private BookmarkRepository bookmarkRepository;

    @Mock
    private BookNoteRepository bookNoteRepository;

    @Mock
    private BookReadingPositionRepository positionRepository;

    private BookService bookService;
    private BookmarkService bookmarkService;
    private BookNoteService bookNoteService;
    private BookReadingPositionService positionService;

    private final UUID userA = UUID.randomUUID();
    private final UUID userB = UUID.randomUUID();
    private final UUID bookId = UUID.randomUUID();
    private final UUID fileId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        bookService = new BookService(bookRepository, userRepository);
        bookmarkService = new BookmarkService(bookmarkRepository, bookRepository, bookFileRepository);
        bookNoteService = new BookNoteService(bookNoteRepository, bookRepository);
        positionService = new BookReadingPositionService(positionRepository, bookRepository, bookFileRepository);

        // When user B tries to access user A's book, the query findByIdAndCreatedBy_Id returns empty
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userB)).thenReturn(Optional.empty());
    }

    @Test
    void userCannotReadOtherUsersBook() {
        assertThatThrownBy(() -> bookService.getBookById(bookId, userB))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void userCannotDeleteOtherUsersBook() {
        assertThatThrownBy(() -> bookService.deleteBook(bookId, userB))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void userCannotCreateBookmarkOnOtherUsersBook() {
        CreateBookmarkRequest req = new CreateBookmarkRequest(
                fileId, "Ch 1", "Note", ReadingLocationType.PDF_PAGE, "page=1", 1
        );

        assertThatThrownBy(() -> bookmarkService.create(userB, bookId, req))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void userCannotCreateNoteOnOtherUsersBook() {
        CreateBookNoteRequest req = new CreateBookNoteRequest("Title", "Content");

        assertThatThrownBy(() -> bookNoteService.create(userB, bookId, req))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void userCannotUpdateReadingPositionOnOtherUsersBook() {
        SaveReadingPositionRequest req = new SaveReadingPositionRequest(
                ReadingLocationType.PDF_PAGE, "page=5", 5, 100, new java.math.BigDecimal("5.00")
        );

        assertThatThrownBy(() -> positionService.saveOrUpdate(userB, bookId, fileId, req))
                .isInstanceOf(ResponseStatusException.class);
    }
}
