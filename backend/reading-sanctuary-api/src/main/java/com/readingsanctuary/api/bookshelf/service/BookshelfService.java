package com.readingsanctuary.api.bookshelf.service;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookshelf.dto.BookshelfResponse;
import com.readingsanctuary.api.bookshelf.dto.CreateBookshelfRequest;
import com.readingsanctuary.api.bookshelf.dto.UpdateBookshelfRequest;
import com.readingsanctuary.api.bookshelf.entity.Bookshelf;
import com.readingsanctuary.api.bookshelf.repository.BookshelfRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
public class BookshelfService {

    private final BookshelfRepository shelfRepository;
    private final BookRepository bookRepository;
    private final UserRepository userRepository;

    public BookshelfService(
            BookshelfRepository shelfRepository,
            BookRepository bookRepository,
            UserRepository userRepository) {

        this.shelfRepository = shelfRepository;
        this.bookRepository = bookRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public BookshelfResponse create(
            UUID userId, CreateBookshelfRequest request) {

        String name = request.name().trim();

        if (shelfRepository.existsByUser_IdAndNameIgnoreCase(userId, name)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Bookshelf already exists");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "User not found"));

        Bookshelf shelf = new Bookshelf();

        shelf.setUser(user);
        shelf.setName(name);
        shelf.setDescription(request.description());
        shelf.setColor(request.color());

        return toResponse(shelfRepository.save(shelf));
    }

    @Transactional(readOnly = true)
    public List<BookshelfResponse> getAll(UUID userId) {

        return shelfRepository.findAllByUser_Id(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public BookshelfResponse update(
            UUID userId,
            UUID shelfId,
            UpdateBookshelfRequest request) {

        Bookshelf shelf = getOwnedShelf(shelfId, userId);

        if (request.name() != null) {

            String name = request.name().trim();

            if (name.isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Shelf name cannot be blank");
            }

            if (!name.equalsIgnoreCase(shelf.getName())
                    && shelfRepository.existsByUser_IdAndNameIgnoreCase(userId, name)) {

                throw new ResponseStatusException(
                        HttpStatus.CONFLICT, "Bookshelf already exists");
            }

            shelf.setName(name);
        }

        if (request.description() != null) {
            shelf.setDescription(request.description());
        }

        if (request.color() != null) {
            shelf.setColor(request.color());
        }

        return toResponse(shelf);
    }

    @Transactional
    public void delete(UUID userId, UUID shelfId) {

        Bookshelf shelf = getOwnedShelf(shelfId, userId);

        shelfRepository.delete(shelf);
    }

    @Transactional
    public void addBook(UUID userId, UUID shelfId, UUID bookId) {

        Bookshelf shelf = getOwnedShelf(shelfId, userId);

        Book book = bookRepository.findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));

        shelf.getBooks().add(book);
    }

    @Transactional
    public void removeBook(UUID userId, UUID shelfId, UUID bookId) {

        Bookshelf shelf = getOwnedShelf(shelfId, userId);

        boolean removed = shelf.getBooks()
                .removeIf(book -> book.getId().equals(bookId));

        if (!removed) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Book not found on bookshelf");
        }
    }

    private Bookshelf getOwnedShelf(UUID shelfId, UUID userId) {

        return shelfRepository.findByIdAndUser_Id(shelfId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Bookshelf not found"));
    }

    private BookshelfResponse toResponse(Bookshelf shelf) {
        List<UUID> bookIds = shelf.getBooks()
                .stream()
                .map(Book::getId)
                .toList();

        return new BookshelfResponse(
                shelf.getId(),
                shelf.getName(),
                shelf.getDescription(),
                shelf.getColor(),
                bookIds.size(),
                bookIds,
                shelf.getCreatedAt()
        );
    }
}
