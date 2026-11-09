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

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.bookmark.dto.BookmarkResponse;
import com.readingsanctuary.api.bookmark.dto.CreateBookmarkRequest;
import com.readingsanctuary.api.bookmark.entity.Bookmark;
import com.readingsanctuary.api.bookmark.repository.BookmarkRepository;
import com.readingsanctuary.api.bookmark.service.BookmarkService;
import com.readingsanctuary.api.common.enums.HighlightColor;
import com.readingsanctuary.api.common.enums.ReadingLocationType;
import com.readingsanctuary.api.highlight.dto.CreateHighlightRequest;
import com.readingsanctuary.api.highlight.dto.HighlightResponse;
import com.readingsanctuary.api.highlight.entity.BookHighlight;
import com.readingsanctuary.api.highlight.repository.BookHighlightRepository;
import com.readingsanctuary.api.highlight.service.HighlightService;
import com.readingsanctuary.api.note.dto.BookNoteResponse;
import com.readingsanctuary.api.note.dto.CreateBookNoteRequest;
import com.readingsanctuary.api.note.entity.BookNote;
import com.readingsanctuary.api.note.repository.BookNoteRepository;
import com.readingsanctuary.api.note.service.BookNoteService;
import com.readingsanctuary.api.user.entity.User;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AnnotationWorkflowIT {

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @Mock
    private BookmarkRepository bookmarkRepository;

    @Mock
    private BookHighlightRepository highlightRepository;

    @Mock
    private BookNoteRepository noteRepository;

    private BookmarkService bookmarkService;
    private HighlightService highlightService;
    private BookNoteService noteService;

    private final UUID userId = UUID.randomUUID();
    private final UUID bookId = UUID.randomUUID();
    private final UUID fileId = UUID.randomUUID();

    private Book book;
    private BookFile bookFile;

    @BeforeEach
    void setUp() {
        bookmarkService = new BookmarkService(bookmarkRepository, bookRepository, bookFileRepository);
        highlightService = new HighlightService(highlightRepository, bookRepository, bookFileRepository);
        noteService = new BookNoteService(noteRepository, bookRepository);

        User user = new User("scholar@sanctuary.com", "hash");
        ReflectionTestUtils.setField(user, "id", userId);

        book = new Book();
        ReflectionTestUtils.setField(book, "id", bookId);
        book.setTitle("Structure and Interpretation of Computer Programs");
        book.setCreatedBy(user);

        bookFile = new BookFile();
        ReflectionTestUtils.setField(bookFile, "id", fileId);
        bookFile.setBook(book);
        bookFile.setFileFormat("PDF");
    }

    @Test
    void completeAnnotationWorkflow_bookmarkHighlightNote() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(bookFile));

        // 1. Create Bookmark
        when(bookmarkRepository.save(any(Bookmark.class))).thenAnswer(i -> {
            Bookmark b = i.getArgument(0);
            ReflectionTestUtils.setField(b, "id", UUID.randomUUID());
            return b;
        });

        CreateBookmarkRequest bmReq = new CreateBookmarkRequest(
                fileId, "Chapter 2: Building Abstractions with Data", "Crucial chapter",
                ReadingLocationType.PDF_PAGE, "page=85", 85
        );
        BookmarkResponse bookmark = bookmarkService.create(userId, bookId, bmReq);
        assertThat(bookmark.label()).isEqualTo("Chapter 2: Building Abstractions with Data");
        assertThat(bookmark.pageNumber()).isEqualTo(85);

        // 2. Create Highlight
        when(highlightRepository.save(any(BookHighlight.class))).thenAnswer(i -> {
            BookHighlight h = i.getArgument(0);
            ReflectionTestUtils.setField(h, "id", UUID.randomUUID());
            return h;
        });

        CreateHighlightRequest hlReq = new CreateHighlightRequest(
                fileId,
                "Programs must be written for people to read, and only incidentally for machines to execute.",
                ReadingLocationType.PDF_PAGE,
                "p85:c0",
                "p85:c90",
                85,
                "#C6A15B",
                "Foundational principle"
        );
        HighlightResponse highlight = highlightService.create(userId, bookId, hlReq);
        assertThat(highlight.colorHex()).isEqualTo("#C6A15B");
        assertThat(highlight.note()).isEqualTo("Foundational principle");

        // 3. Create Note
        when(noteRepository.save(any(BookNote.class))).thenAnswer(i -> {
            BookNote n = i.getArgument(0);
            ReflectionTestUtils.setField(n, "id", UUID.randomUUID());
            return n;
        });

        CreateBookNoteRequest noteReq = new CreateBookNoteRequest(
                "Key takeaways on functional abstraction",
                "Data abstraction provides barriers that isolate how a data object is used from how it is represented."
        );
        BookNoteResponse note = noteService.create(userId, bookId, noteReq);
        assertThat(note.title()).isEqualTo("Key takeaways on functional abstraction");
        assertThat(note.content()).contains("Data abstraction provides barriers");
    }
}
