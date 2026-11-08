package com.readingsanctuary.api.collection.service;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.collection.dto.CollectionResponse;
import com.readingsanctuary.api.collection.dto.CreateCollectionRequest;
import com.readingsanctuary.api.collection.dto.UpdateCollectionRequest;
import com.readingsanctuary.api.collection.entity.BookCollection;
import com.readingsanctuary.api.collection.repository.BookCollectionRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
public class CollectionService {

    private final BookCollectionRepository collectionRepository;
    private final BookRepository bookRepository;
    private final UserRepository userRepository;

    public CollectionService(
            BookCollectionRepository collectionRepository,
            BookRepository bookRepository,
            UserRepository userRepository) {

        this.collectionRepository = collectionRepository;
        this.bookRepository = bookRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public CollectionResponse create(
            UUID userId,
            CreateCollectionRequest request) {

        String name = request.name().trim();

        BookCollection parent = null;

        if (request.parentId() != null) {
            parent = getOwnedCollection(request.parentId(), userId);
        }

        validateUniqueName(userId, name, parent == null ? null : parent.getId());

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "User not found"));

        BookCollection collection = new BookCollection();
        collection.setUser(user);
        collection.setName(name);
        collection.setDescription(request.description());
        collection.setParent(parent);

        return toResponse(collectionRepository.save(collection));
    }

    @Transactional(readOnly = true)
    public List<CollectionResponse> getAll(UUID userId) {

        return collectionRepository.findAllByUser_Id(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public CollectionResponse update(
            UUID userId,
            UUID collectionId,
            UpdateCollectionRequest request) {

        BookCollection collection = getOwnedCollection(collectionId, userId);

        if (request.name() != null) {
            String name = request.name().trim();

            if (name.isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Collection name cannot be blank");
            }

            if (!name.equalsIgnoreCase(collection.getName())) {
                validateUniqueName(
                        userId,
                        name,
                        collection.getParent() == null
                                ? null
                                : collection.getParent().getId());
            }

            collection.setName(name);
        }

        if (request.description() != null) {
            collection.setDescription(request.description());
        }

        if (request.parentId() != null) {
            if (request.parentId().equals(collectionId)) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "A collection cannot be its own parent");
            }

            BookCollection newParent = getOwnedCollection(request.parentId(), userId);

            if (isDescendant(collectionId, newParent, userId)) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Circular collection hierarchy is not allowed");
            }

            collection.setParent(newParent);
        }

        return toResponse(collection);
    }

    @Transactional
    public void delete(UUID userId, UUID collectionId) {

        BookCollection collection = getOwnedCollection(collectionId, userId);

        collectionRepository.delete(collection);
    }

    @Transactional
    public void addBook(
            UUID userId,
            UUID collectionId,
            UUID bookId) {

        BookCollection collection = getOwnedCollection(collectionId, userId);

        Book book = bookRepository.findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));

        collection.getBooks().add(book);
    }

    @Transactional
    public void removeBook(
            UUID userId,
            UUID collectionId,
            UUID bookId) {

        BookCollection collection = getOwnedCollection(collectionId, userId);

        boolean removed = collection.getBooks()
                .removeIf(book -> book.getId().equals(bookId));

        if (!removed) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Book not found in collection");
        }
    }

    private BookCollection getOwnedCollection(UUID collectionId, UUID userId) {

        return collectionRepository
                .findByIdAndUser_Id(collectionId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Collection not found"));
    }

    private void validateUniqueName(UUID userId, String name, UUID parentId) {

        if (collectionRepository.existsByUserAndNameAndParent(userId, name, parentId)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Collection already exists at this level");
        }
    }

    private boolean isDescendant(
            UUID collectionId,
            BookCollection possibleDescendant,
            UUID userId) {

        BookCollection current = possibleDescendant;
        while (current != null) {
            if (current.getId().equals(collectionId)) {
                return true;
            }
            current = current.getParent();
        }
        return false;
    }

    private CollectionResponse toResponse(BookCollection collection) {

        List<UUID> bookIds = collection.getBooks()
                .stream()
                .map(Book::getId)
                .toList();

        return new CollectionResponse(
                collection.getId(),
                collection.getName(),
                collection.getDescription(),
                collection.getParent() == null ? null : collection.getParent().getId(),
                bookIds.size(),
                bookIds,
                collection.getCreatedAt()
        );
    }
}
