package com.readingsanctuary.api.bookmetadata.service;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookmetadata.author.entity.Author;
import com.readingsanctuary.api.bookmetadata.author.repository.AuthorRepository;
import com.readingsanctuary.api.bookmetadata.dto.*;
import com.readingsanctuary.api.bookmetadata.genre.entity.Genre;
import com.readingsanctuary.api.bookmetadata.genre.repository.GenreRepository;

@Service
public class BookMetadataService {

    private final BookRepository bookRepository;
    private final AuthorRepository authorRepository;
    private final GenreRepository genreRepository;

    public BookMetadataService(
            BookRepository bookRepository,
            AuthorRepository authorRepository,
            GenreRepository genreRepository) {

        this.bookRepository = bookRepository;
        this.authorRepository = authorRepository;
        this.genreRepository = genreRepository;
    }

    @Transactional
    public BookMetadataResponse updateMetadata(
            UUID userId,
            UUID bookId,
            BookMetadataRequest request) {

        Book book = getOwnedBook(bookId, userId);

        if (request.title() != null) {
            if (request.title().isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Title cannot be blank");
            }
            book.setTitle(request.title().trim());
        }

        if (request.isbn() != null) {
            book.setIsbn(request.isbn().trim());
        }

        if (request.publisher() != null) {
            book.setPublisher(request.publisher().trim());
        }

        if (request.language() != null) {
            book.setLanguage(request.language().trim());
        }

        if (request.publicationDate() != null) {
            book.setPublicationDate(request.publicationDate());
        }

        if (request.description() != null) {
            book.setDescription(request.description().trim());
        }

        if (request.authorIds() != null) {
            Set<Author> authors =
                    new HashSet<>(authorRepository.findAllById(request.authorIds()));

            if (authors.size() != request.authorIds().size()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "One or more authors do not exist");
            }

            book.setAuthors(authors);
        }

        if (request.genreIds() != null) {
            Set<Genre> genres =
                    new HashSet<>(genreRepository.findAllById(request.genreIds()));

            if (genres.size() != request.genreIds().size()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "One or more genres do not exist");
            }

            book.setGenres(genres);
        }

        return toResponse(book);
    }

    @Transactional(readOnly = true)
    public BookMetadataResponse getMetadata(UUID userId, UUID bookId) {

        Book book = getOwnedBook(bookId, userId);

        return toResponse(book);
    }

    private Book getOwnedBook(UUID bookId, UUID userId) {

        return bookRepository.findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));
    }

    private BookMetadataResponse toResponse(Book book) {

        Set<AuthorResponse> authors = book.getAuthors()
                .stream()
                .map(author -> new AuthorResponse(
                        author.getId(),
                        author.getName(),
                        author.getBiography()))
                .collect(Collectors.toSet());

        Set<GenreResponse> genres = book.getGenres()
                .stream()
                .map(genre -> new GenreResponse(
                        genre.getId(),
                        genre.getName(),
                        genre.getDescription()))
                .collect(Collectors.toSet());

        String coverUrl = book.getCoverStorageKey() == null
                ? null
                : "/api/v1/books/" + book.getId() + "/cover";

        return new BookMetadataResponse(
                book.getId(),
                book.getTitle(),
                book.getIsbn(),
                book.getPublisher(),
                book.getLanguage(),
                book.getPublicationDate(),
                book.getDescription(),
                authors,
                genres,
                coverUrl,
                book.getCoverUpdatedAt()
        );
    }
}
