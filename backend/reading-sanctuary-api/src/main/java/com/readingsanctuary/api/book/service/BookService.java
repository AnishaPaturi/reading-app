package com.readingsanctuary.api.book.service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.dto.BookResponse;
import com.readingsanctuary.api.book.dto.CreateBookRequest;
import com.readingsanctuary.api.book.dto.UpdateBookRequest;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;
import com.readingsanctuary.api.sync.service.SyncChangePublisher;
import org.springframework.beans.factory.annotation.Autowired;

@Service
public class BookService {

    private final BookRepository bookRepository;
    private final UserRepository userRepository;
    private final SyncChangePublisher changePublisher;
    private final BookFileRepository bookFileRepository;
    private final BookStorageService bookStorageService;

    public BookService(
            BookRepository bookRepository,
            UserRepository userRepository) {
        this(bookRepository, userRepository, null, null, null);
    }

    public BookService(
            BookRepository bookRepository,
            UserRepository userRepository,
            SyncChangePublisher changePublisher) {
        this(bookRepository, userRepository, changePublisher, null, null);
    }

    @Autowired
    public BookService(
            BookRepository bookRepository,
            UserRepository userRepository,
            @Autowired(required = false) SyncChangePublisher changePublisher,
            @Autowired(required = false) BookFileRepository bookFileRepository,
            @Autowired(required = false) BookStorageService bookStorageService) {
        this.bookRepository = bookRepository;
        this.userRepository = userRepository;
        this.changePublisher = changePublisher;
        this.bookFileRepository = bookFileRepository;
        this.bookStorageService = bookStorageService;
    }

    // Create a new book
    @Transactional
    public BookResponse createBook(CreateBookRequest request, UUID userId) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "User not found"));

        Book book = new Book();
        book.setTitle(request.title().trim());
        book.setDescription(request.description());
        book.setLanguage(request.language());
        book.setPublisher(request.publisher());
        book.setPublicationDate(request.publicationDate());
        book.setIsbn(request.isbn());
        book.setCreatedBy(user);

        Book savedBook = bookRepository.save(book);
        BookResponse response = mapToResponse(savedBook);
        if (changePublisher != null) {
            changePublisher.publishCreate(userId, "BOOK", savedBook.getId().toString(), 1L, response);
        }
        return response;
    }

    // Get all active books belonging to the authenticated user (excludes DELETED)
    @Transactional(readOnly = true)
    public List<BookResponse> getAllBooks(UUID userId) {

        return bookRepository.findAllByCreatedBy_IdAndReadingStatusNot(userId, ReadingStatus.DELETED)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    // Get deleted books belonging to the authenticated user
    @Transactional(readOnly = true)
    public List<BookResponse> getDeletedBooks(UUID userId) {

        return bookRepository
                .findAllByCreatedBy_IdAndReadingStatus(
                        userId,
                        ReadingStatus.DELETED
                )
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    // Get one book belonging to the authenticated user
    @Transactional(readOnly = true)
    public BookResponse getBookById(UUID bookId, UUID userId) {

        Book book = findOwnedBook(bookId, userId);

        return mapToResponse(book);
    }

    // Update an existing book
    @Transactional
    public BookResponse updateBook(
            UUID bookId,
            UpdateBookRequest request,
            UUID userId) {

        Book book = findOwnedBook(bookId, userId);

        book.setTitle(request.title().trim());
        book.setDescription(request.description());
        book.setLanguage(request.language());
        book.setPublisher(request.publisher());
        book.setPublicationDate(request.publicationDate());
        book.setIsbn(request.isbn());

        Book updatedBook = bookRepository.save(book);
        BookResponse response = mapToResponse(updatedBook);
        if (changePublisher != null) {
            changePublisher.publishUpdate(userId, "BOOK", updatedBook.getId().toString(), 2L, response);
        }
        return response;
    }

    // Soft delete a book (move to Deleted)
    @Transactional
    public void deleteBook(UUID bookId, UUID userId) {

        Book book = findOwnedBook(bookId, userId);

        if (book.getReadingStatus() == ReadingStatus.DELETED) {
            return;
        }

        book.setPreviousReadingStatus(book.getReadingStatus());
        book.setReadingStatus(ReadingStatus.DELETED);
        book.setDeletedAt(OffsetDateTime.now());

        bookRepository.save(book);

        if (changePublisher != null) {
            changePublisher.publishUpdate(userId, "BOOK", bookId.toString(), 2L, mapToResponse(book));
        }
    }

    // Restore a book from Deleted back to its previous status
    @Transactional
    public void restoreBook(UUID bookId, UUID userId) {

        Book book = findOwnedBook(bookId, userId);

        if (book.getReadingStatus() != ReadingStatus.DELETED) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Book is not in Deleted"
            );
        }

        ReadingStatus previous = book.getPreviousReadingStatus();

        if (previous == null || previous == ReadingStatus.DELETED) {
            previous = ReadingStatus.TO_READ;
        }

        book.setReadingStatus(previous);
        book.setPreviousReadingStatus(null);
        book.setDeletedAt(null);

        bookRepository.save(book);

        if (changePublisher != null) {
            changePublisher.publishUpdate(userId, "BOOK", bookId.toString(), 2L, mapToResponse(book));
        }
    }

    // Permanently delete a book and its physical files
    @Transactional
    public void permanentlyDeleteBook(UUID bookId, UUID userId) {

        Book book = findOwnedBook(bookId, userId);

        if (book.getReadingStatus() != ReadingStatus.DELETED) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Move the book to Deleted first"
            );
        }

        List<String> storageKeys = List.of();
        if (bookFileRepository != null) {
            try {
                storageKeys = bookFileRepository.findAllByBook_Id(bookId)
                        .stream()
                        .map(BookFile::getStorageKey)
                        .filter(k -> k != null && !k.isBlank())
                        .toList();
            } catch (Exception ignored) {}
        }

        bookRepository.delete(book);

        if (changePublisher != null) {
            changePublisher.publishDelete(userId, "BOOK", bookId.toString(), 3L);
        }

        if (bookStorageService != null) {
            for (String key : storageKeys) {
                try {
                    bookStorageService.delete(key);
                } catch (Exception ignored) {}
            }
        }
    }

    // Verify that the book belongs to the authenticated user
    private Book findOwnedBook(UUID bookId, UUID userId) {

        return bookRepository.findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));
    }

    // Convert entity into response DTO
    private BookResponse mapToResponse(Book book) {

        return new BookResponse(
                book.getId(),
                book.getTitle(),
                book.getDescription(),
                book.getLanguage(),
                book.getPublisher(),
                book.getPublicationDate(),
                book.getIsbn(),
                book.getCreatedAt(),
                book.getUpdatedAt(),
                book.getPreviousReadingStatus() != null ? book.getPreviousReadingStatus().name() : null,
                book.getDeletedAt()
        );
    }
}
