package com.readingsanctuary.api.bookmark;

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
import com.readingsanctuary.api.bookmark.dto.BookmarkResponse;
import com.readingsanctuary.api.bookmark.dto.CreateBookmarkRequest;
import com.readingsanctuary.api.bookmark.dto.UpdateBookmarkRequest;
import com.readingsanctuary.api.bookmark.entity.Bookmark;
import com.readingsanctuary.api.bookmark.repository.BookmarkRepository;
import com.readingsanctuary.api.bookmark.service.BookmarkService;
import com.readingsanctuary.api.common.enums.ReadingLocationType;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookmarkServiceTest {

    @Mock
    private BookmarkRepository bookmarkRepository;

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @InjectMocks
    private BookmarkService bookmarkService;

    private UUID userId;
    private UUID otherUserId;
    private UUID bookId;
    private UUID fileId;
    private Book book;
    private BookFile pdfFile;
    private BookFile epubFile;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        otherUserId = UUID.randomUUID();
        bookId = UUID.randomUUID();
        fileId = UUID.randomUUID();

        book = new Book();
        book.setId(bookId);

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
    void createBookmark_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(pdfFile));
        when(bookmarkRepository.save(any(Bookmark.class))).thenAnswer(invocation -> {
            Bookmark b = invocation.getArgument(0);
            ReflectionTestUtils.setField(b, "id", UUID.randomUUID());
            return b;
        });

        CreateBookmarkRequest request = new CreateBookmarkRequest(
                fileId, "Chapter 1", "Note", ReadingLocationType.PDF_PAGE, "page=15", 15);

        BookmarkResponse response = bookmarkService.create(userId, bookId, request);

        assertThat(response.bookId()).isEqualTo(bookId);
        assertThat(response.bookFileId()).isEqualTo(fileId);
        assertThat(response.label()).isEqualTo("Chapter 1");
        assertThat(response.note()).isEqualTo("Note");
        assertThat(response.locationType()).isEqualTo(ReadingLocationType.PDF_PAGE);
        assertThat(response.locationValue()).isEqualTo("page=15");
        assertThat(response.pageNumber()).isEqualTo(15);
    }

    @Test
    void createBookmark_FormatMismatch_ThrowsBadRequest() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(epubFile));

        CreateBookmarkRequest request = new CreateBookmarkRequest(
                fileId, "Chapter 1", "Note", ReadingLocationType.PDF_PAGE, "page=15", 15);

        assertThatThrownBy(() -> bookmarkService.create(userId, bookId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void createBookmark_UnownedBook_ThrowsNotFound() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, otherUserId)).thenReturn(Optional.empty());

        CreateBookmarkRequest request = new CreateBookmarkRequest(
                fileId, "Chapter 1", "Note", ReadingLocationType.PDF_PAGE, "page=15", 15);

        assertThatThrownBy(() -> bookmarkService.create(otherUserId, bookId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    void createBookmark_FileNotFoundForBook_ThrowsNotFound() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.empty());

        CreateBookmarkRequest request = new CreateBookmarkRequest(
                fileId, "Chapter 1", "Note", ReadingLocationType.PDF_PAGE, "page=15", 15);

        assertThatThrownBy(() -> bookmarkService.create(userId, bookId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    void getAllBookmarks_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        Bookmark b1 = new Bookmark();
        ReflectionTestUtils.setField(b1, "id", UUID.randomUUID());
        b1.setBook(book);
        b1.setBookFile(pdfFile);
        b1.setLabel("Bookmark 1");
        b1.setLocationType(ReadingLocationType.PDF_PAGE);
        b1.setLocationValue("page=1");

        when(bookmarkRepository.findAllByBook_IdOrderByCreatedAtDesc(bookId)).thenReturn(List.of(b1));

        List<BookmarkResponse> list = bookmarkService.getAll(userId, bookId);

        assertThat(list).hasSize(1);
        assertThat(list.get(0).label()).isEqualTo("Bookmark 1");
    }

    @Test
    void updateBookmark_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        UUID bookmarkId = UUID.randomUUID();
        Bookmark bookmark = new Bookmark();
        ReflectionTestUtils.setField(bookmark, "id", bookmarkId);
        bookmark.setBook(book);
        bookmark.setBookFile(pdfFile);
        bookmark.setLabel("Old label");
        bookmark.setLocationType(ReadingLocationType.PDF_PAGE);
        bookmark.setLocationValue("page=1");

        when(bookmarkRepository.findByIdAndBook_Id(bookmarkId, bookId)).thenReturn(Optional.of(bookmark));
        when(bookmarkRepository.save(any(Bookmark.class))).thenAnswer(inv -> inv.getArgument(0));

        UpdateBookmarkRequest updateRequest = new UpdateBookmarkRequest("New label", "New note");
        BookmarkResponse updated = bookmarkService.update(userId, bookId, bookmarkId, updateRequest);

        assertThat(updated.label()).isEqualTo("New label");
        assertThat(updated.note()).isEqualTo("New note");
    }

    @Test
    void deleteBookmark_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        UUID bookmarkId = UUID.randomUUID();
        Bookmark bookmark = new Bookmark();
        bookmark.setBook(book);
        bookmark.setBookFile(pdfFile);

        when(bookmarkRepository.findByIdAndBook_Id(bookmarkId, bookId)).thenReturn(Optional.of(bookmark));

        bookmarkService.delete(userId, bookId, bookmarkId);

        verify(bookmarkRepository).delete(bookmark);
    }

    @Test
    void deleteBookmark_NotFound_ThrowsNotFound() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));

        UUID bookmarkId = UUID.randomUUID();
        when(bookmarkRepository.findByIdAndBook_Id(bookmarkId, bookId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookmarkService.delete(userId, bookId, bookmarkId))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }
}
