package com.readingsanctuary.api.bookmark.service;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.bookmark.dto.*;
import com.readingsanctuary.api.bookmark.entity.Bookmark;
import com.readingsanctuary.api.bookmark.repository.BookmarkRepository;
import com.readingsanctuary.api.common.enums.ReadingLocationType;
import com.readingsanctuary.api.sync.service.SyncChangePublisher;
import org.springframework.beans.factory.annotation.Autowired;

@Service
@Transactional
public class BookmarkService {

    private final BookmarkRepository bookmarkRepository;
    private final BookRepository bookRepository;
    private final BookFileRepository bookFileRepository;
    private final SyncChangePublisher changePublisher;

    public BookmarkService(
            BookmarkRepository bookmarkRepository,
            BookRepository bookRepository,
            BookFileRepository bookFileRepository) {
        this(bookmarkRepository, bookRepository, bookFileRepository, null);
    }

    @Autowired
    public BookmarkService(
            BookmarkRepository bookmarkRepository,
            BookRepository bookRepository,
            BookFileRepository bookFileRepository,
            @Autowired(required = false) SyncChangePublisher changePublisher) {
        this.bookmarkRepository = bookmarkRepository;
        this.bookRepository = bookRepository;
        this.bookFileRepository = bookFileRepository;
        this.changePublisher = changePublisher;
    }

    public BookmarkResponse create(
            UUID userId, UUID bookId,
            CreateBookmarkRequest request) {

        Book book = getOwnedBook(bookId, userId);
        BookFile file = getBookFile(request.bookFileId(), bookId);

        validateFormat(file, request.locationType());

        Bookmark bookmark = new Bookmark();
        bookmark.setBook(book);
        bookmark.setBookFile(file);
        bookmark.setLabel(request.label());
        bookmark.setNote(request.note());
        bookmark.setLocationType(request.locationType());
        bookmark.setLocationValue(request.locationValue());
        bookmark.setPageNumber(request.pageNumber());

        Bookmark saved = bookmarkRepository.save(bookmark);
        if (changePublisher != null) {
            changePublisher.publishCreate(userId, "BOOKMARK", saved.getId().toString(), 1L, toResponse(saved));
        }
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<BookmarkResponse> getAll(
            UUID userId, UUID bookId) {

        getOwnedBook(bookId, userId);

        return bookmarkRepository
                .findAllByBook_IdOrderByCreatedAtDesc(bookId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public BookmarkResponse update(
            UUID userId, UUID bookId, UUID bookmarkId,
            UpdateBookmarkRequest request) {

        getOwnedBook(bookId, userId);

        Bookmark bookmark = bookmarkRepository
                .findByIdAndBook_Id(bookmarkId, bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Bookmark not found"));

        if (request.label() != null) {
            bookmark.setLabel(request.label());
        }

        if (request.note() != null) {
            bookmark.setNote(request.note());
        }

        Bookmark saved = bookmarkRepository.save(bookmark);
        if (changePublisher != null) {
            changePublisher.publishCreate(userId, "BOOKMARK", saved.getId().toString(), 1L, toResponse(saved));
        }
        return toResponse(saved);
    }

    public void delete(
            UUID userId, UUID bookId, UUID bookmarkId) {

        getOwnedBook(bookId, userId);

        Bookmark bookmark = bookmarkRepository
                .findByIdAndBook_Id(bookmarkId, bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Bookmark not found"));

        bookmarkRepository.delete(bookmark);
    }

    private Book getOwnedBook(UUID bookId, UUID userId) {
        return bookRepository
                .findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));
    }

    private BookFile getBookFile(UUID fileId, UUID bookId) {
        return bookFileRepository
                .findByIdAndBook_Id(fileId, bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "File not found for this book"));
    }

    private void validateFormat(
            BookFile file,
            ReadingLocationType type) {

        String format = file.getFileFormat().toString();

        boolean valid = switch (type) {
            case PDF_PAGE -> format.equalsIgnoreCase("PDF");
            case EPUB_CFI -> format.equalsIgnoreCase("EPUB");
            case DOCX_ANCHOR -> format.equalsIgnoreCase("DOCX");
        };

        if (!valid) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Reading location type does not match uploaded file format");
        }
    }

    private BookmarkResponse toResponse(Bookmark b) {
        return new BookmarkResponse(
                b.getId(),
                b.getBook().getId(),
                b.getBookFile().getId(),
                b.getLabel(),
                b.getNote(),
                b.getLocationType(),
                b.getLocationValue(),
                b.getPageNumber(),
                b.getCreatedAt(),
                b.getUpdatedAt()
        );
    }
}
