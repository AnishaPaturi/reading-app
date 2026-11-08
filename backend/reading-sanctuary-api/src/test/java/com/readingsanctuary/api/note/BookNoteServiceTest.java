package com.readingsanctuary.api.note;

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
import com.readingsanctuary.api.note.dto.BookNoteResponse;
import com.readingsanctuary.api.note.dto.CreateBookNoteRequest;
import com.readingsanctuary.api.note.dto.UpdateBookNoteRequest;
import com.readingsanctuary.api.note.entity.BookNote;
import com.readingsanctuary.api.note.repository.BookNoteRepository;
import com.readingsanctuary.api.note.service.BookNoteService;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookNoteServiceTest {

    @Mock
    private BookNoteRepository noteRepository;

    @Mock
    private BookRepository bookRepository;

    @InjectMocks
    private BookNoteService noteService;

    private UUID userId;
    private UUID otherUserId;
    private UUID bookId;
    private Book book;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        otherUserId = UUID.randomUUID();
        bookId = UUID.randomUUID();

        book = new Book();
        book.setId(bookId);
    }

    @Test
    void createNote_Success_TrimsTitle() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(noteRepository.save(any(BookNote.class))).thenAnswer(invocation -> {
            BookNote n = invocation.getArgument(0);
            ReflectionTestUtils.setField(n, "id", UUID.randomUUID());
            return n;
        });

        CreateBookNoteRequest request = new CreateBookNoteRequest("  My Review Note  ", "Comprehensive thoughts on the book.");
        BookNoteResponse response = noteService.create(userId, bookId, request);

        assertThat(response.bookId()).isEqualTo(bookId);
        assertThat(response.title()).isEqualTo("My Review Note");
        assertThat(response.content()).isEqualTo("Comprehensive thoughts on the book.");
    }

    @Test
    void createNote_UnownedBook_ThrowsNotFound() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, otherUserId)).thenReturn(Optional.empty());

        CreateBookNoteRequest request = new CreateBookNoteRequest("Title", "Content");

        assertThatThrownBy(() -> noteService.create(otherUserId, bookId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    void getAllNotes_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        BookNote note = new BookNote();
        ReflectionTestUtils.setField(note, "id", UUID.randomUUID());
        note.setBook(book);
        note.setTitle("Note 1");
        note.setContent("Content 1");

        when(noteRepository.findAllByBook_IdOrderByUpdatedAtDesc(bookId)).thenReturn(List.of(note));

        List<BookNoteResponse> list = noteService.getAll(userId, bookId);

        assertThat(list).hasSize(1);
        assertThat(list.get(0).title()).isEqualTo("Note 1");
    }

    @Test
    void getOneNote_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        UUID noteId = UUID.randomUUID();
        BookNote note = new BookNote();
        ReflectionTestUtils.setField(note, "id", noteId);
        note.setBook(book);
        note.setTitle("Note 1");
        note.setContent("Content 1");

        when(noteRepository.findByIdAndBook_Id(noteId, bookId)).thenReturn(Optional.of(note));

        BookNoteResponse found = noteService.getOne(userId, bookId, noteId);

        assertThat(found.id()).isEqualTo(noteId);
        assertThat(found.title()).isEqualTo("Note 1");
    }

    @Test
    void getOneNote_NotFound_ThrowsNotFound() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        UUID noteId = UUID.randomUUID();
        when(noteRepository.findByIdAndBook_Id(noteId, bookId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> noteService.getOne(userId, bookId, noteId))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    void updateNote_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        UUID noteId = UUID.randomUUID();
        BookNote note = new BookNote();
        ReflectionTestUtils.setField(note, "id", noteId);
        note.setBook(book);
        note.setTitle("Old Title");
        note.setContent("Old Content");

        when(noteRepository.findByIdAndBook_Id(noteId, bookId)).thenReturn(Optional.of(note));
        when(noteRepository.save(any(BookNote.class))).thenAnswer(inv -> inv.getArgument(0));

        UpdateBookNoteRequest updateRequest = new UpdateBookNoteRequest("  Updated Title  ", "Updated Content");
        BookNoteResponse updated = noteService.update(userId, bookId, noteId, updateRequest);

        assertThat(updated.title()).isEqualTo("Updated Title");
        assertThat(updated.content()).isEqualTo("Updated Content");
    }

    @Test
    void deleteNote_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        UUID noteId = UUID.randomUUID();
        BookNote note = new BookNote();
        note.setBook(book);

        when(noteRepository.findByIdAndBook_Id(noteId, bookId)).thenReturn(Optional.of(note));

        noteService.delete(userId, bookId, noteId);

        verify(noteRepository).delete(note);
    }
}
