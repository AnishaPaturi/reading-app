package com.readingsanctuary.api.book.service;

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
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
public class BookService {

    private final BookRepository bookRepository;
    private final UserRepository userRepository;

    public BookService(
            BookRepository bookRepository,
            UserRepository userRepository) {
        this.bookRepository = bookRepository;
        this.userRepository = userRepository;
    }

    // Create a new book
    @Transactional
    public BookResponse createBook(CreateBookRequest request, UUID userId) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "User not found"));

        Book book = new Book();

        book.setCreatedBy(user);
        book.setTitle(request.title().trim());
        book.setDescription(request.description());
        book.setLanguage(request.language());
        book.setPublisher(request.publisher());
        book.setPublicationDate(request.publicationDate());
        book.setIsbn(request.isbn());

        Book savedBook = bookRepository.save(book);

        return mapToResponse(savedBook);
    }

    // Get all books belonging to the authenticated user
    @Transactional(readOnly = true)
    public List<BookResponse> getAllBooks(UUID userId) {

        return bookRepository.findAllByCreatedBy_Id(userId)
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

        return mapToResponse(updatedBook);
    }

    // Delete a book belonging to the authenticated user
    @Transactional
    public void deleteBook(UUID bookId, UUID userId) {

        Book book = findOwnedBook(bookId, userId);

        bookRepository.delete(book);
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
                book.getUpdatedAt()
        );
    }
}
