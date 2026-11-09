package com.readingsanctuary.api.note.service;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.note.dto.*;
import com.readingsanctuary.api.note.entity.BookNote;
import com.readingsanctuary.api.note.repository.BookNoteRepository;
import com.readingsanctuary.api.sync.service.SyncChangePublisher;
import org.springframework.beans.factory.annotation.Autowired;

@Service
@Transactional
public class BookNoteService {

    private final BookNoteRepository noteRepository;
    private final BookRepository bookRepository;
    private final SyncChangePublisher changePublisher;

    public BookNoteService(
            BookNoteRepository noteRepository,
            BookRepository bookRepository) {
        this(noteRepository, bookRepository, null);
    }

    @Autowired
    public BookNoteService(
            BookNoteRepository noteRepository,
            BookRepository bookRepository,
            @Autowired(required = false) SyncChangePublisher changePublisher) {
        this.noteRepository = noteRepository;
        this.bookRepository = bookRepository;
        this.changePublisher = changePublisher;
    }

    public BookNoteResponse create(
            UUID userId, UUID bookId,
            CreateBookNoteRequest request) {

        Book book = getOwnedBook(bookId, userId);

        BookNote note = new BookNote();
        note.setBook(book);
        note.setTitle(request.title().trim());
        note.setContent(request.content());

        BookNote saved = noteRepository.save(note);
        if (changePublisher != null) {
            changePublisher.publishCreate(userId, "BOOK_NOTE", saved.getId().toString(), 1L, toResponse(saved));
        }
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<BookNoteResponse> getAll(
            UUID userId, UUID bookId) {

        getOwnedBook(bookId, userId);

        return noteRepository
                .findAllByBook_IdOrderByUpdatedAtDesc(bookId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public BookNoteResponse getOne(
            UUID userId, UUID bookId, UUID noteId) {

        getOwnedBook(bookId, userId);

        return toResponse(getNote(bookId, noteId));
    }

    public BookNoteResponse update(
            UUID userId, UUID bookId, UUID noteId,
            UpdateBookNoteRequest request) {

        getOwnedBook(bookId, userId);

        BookNote note = getNote(bookId, noteId);
        note.setTitle(request.title().trim());
        note.setContent(request.content());

        BookNote saved = noteRepository.save(note);
        if (changePublisher != null) {
            changePublisher.publishUpdate(userId, "BOOK_NOTE", saved.getId().toString(), 2L, toResponse(saved));
        }
        return toResponse(saved);
    }

    public void delete(
            UUID userId, UUID bookId, UUID noteId) {

        getOwnedBook(bookId, userId);
        BookNote note = getNote(bookId, noteId);
        noteRepository.delete(note);
        if (changePublisher != null) {
            changePublisher.publishDelete(userId, "BOOK_NOTE", noteId.toString(), 3L);
        }
    }

    private Book getOwnedBook(UUID bookId, UUID userId) {
        return bookRepository
                .findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));
    }

    private BookNote getNote(UUID bookId, UUID noteId) {
        return noteRepository
                .findByIdAndBook_Id(noteId, bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Note not found"));
    }

    private BookNoteResponse toResponse(BookNote n) {
        return new BookNoteResponse(
                n.getId(),
                n.getBook().getId(),
                n.getTitle(),
                n.getContent(),
                n.getCreatedAt(),
                n.getUpdatedAt()
        );
    }
}
