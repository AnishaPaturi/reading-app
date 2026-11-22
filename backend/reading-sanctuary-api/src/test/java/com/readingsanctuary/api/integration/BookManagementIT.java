package com.readingsanctuary.api.integration;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import com.readingsanctuary.api.book.dto.BookResponse;
import com.readingsanctuary.api.book.dto.CreateBookRequest;
import com.readingsanctuary.api.book.dto.UpdateBookRequest;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.book.service.BookService;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BookManagementIT {

    @Mock
    private BookRepository bookRepository;

    @Mock
    private UserRepository userRepository;

    private BookService bookService;

    private final UUID userId = UUID.randomUUID();
    private User testUser;

    @BeforeEach
    void setUp() {
        bookService = new BookService(bookRepository, userRepository);

        testUser = new User("sanctuary@test.com", "hash");
        ReflectionTestUtils.setField(testUser, "id", userId);
    }

    @Test
    void completeBookLifecycle_createUpdateRetrieveDelete() {
        // 1. Create Book
        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(bookRepository.save(any(Book.class))).thenAnswer(invocation -> {
            Book b = invocation.getArgument(0);
            if (b.getId() == null) {
                ReflectionTestUtils.setField(b, "id", UUID.randomUUID());
            }
            return b;
        });

        CreateBookRequest createReq = new CreateBookRequest(
                "Refactoring", "Martin Fowler", "en", "Addison-Wesley", null, "978-0201485677"
        );
        BookResponse created = bookService.createBook(createReq, userId);
        assertThat(created).isNotNull();
        assertThat(created.title()).isEqualTo("Refactoring");

        UUID bookId = created.id();

        // 2. Retrieve Book
        Book savedBook = new Book();
        ReflectionTestUtils.setField(savedBook, "id", bookId);
        savedBook.setTitle("Refactoring");
        savedBook.setReadingStatus(ReadingStatus.TO_READ);
        savedBook.setCreatedBy(testUser);

        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(savedBook));
        BookResponse retrieved = bookService.getBookById(bookId, userId);
        assertThat(retrieved.id()).isEqualTo(bookId);
        assertThat(retrieved.title()).isEqualTo("Refactoring");

        // 3. Update Book
        UpdateBookRequest updateReq = new UpdateBookRequest(
                "Refactoring 2nd Ed", "Martin Fowler", "en", "Addison-Wesley", null, "978-0134757599"
        );
        BookResponse updated = bookService.updateBook(bookId, updateReq, userId);
        assertThat(updated.title()).isEqualTo("Refactoring 2nd Ed");

        // 4. Soft Delete Book (Move to Deleted)
        bookService.deleteBook(bookId, userId);
        assertThat(savedBook.getReadingStatus()).isEqualTo(ReadingStatus.DELETED);
        assertThat(savedBook.getPreviousReadingStatus()).isEqualTo(ReadingStatus.TO_READ);
        assertThat(savedBook.getDeletedAt()).isNotNull();
        verify(bookRepository, atLeastOnce()).save(savedBook);

        // 5. Restore Book
        bookService.restoreBook(bookId, userId);
        assertThat(savedBook.getReadingStatus()).isEqualTo(ReadingStatus.TO_READ);
        assertThat(savedBook.getPreviousReadingStatus()).isNull();
        assertThat(savedBook.getDeletedAt()).isNull();

        // 6. Soft Delete again and Permanently Delete
        bookService.deleteBook(bookId, userId);
        bookService.permanentlyDeleteBook(bookId, userId);
        verify(bookRepository).delete(savedBook);
    }
}
