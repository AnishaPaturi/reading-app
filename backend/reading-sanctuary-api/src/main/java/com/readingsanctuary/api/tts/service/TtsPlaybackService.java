package com.readingsanctuary.api.tts.service;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.tts.dto.SaveTtsPositionRequest;
import com.readingsanctuary.api.tts.dto.TtsPositionResponse;
import com.readingsanctuary.api.tts.entity.TtsPlaybackPosition;
import com.readingsanctuary.api.tts.repository.TtsPlaybackPositionRepository;
import com.readingsanctuary.api.sync.service.SyncChangePublisher;
import org.springframework.beans.factory.annotation.Autowired;

@Service
@Transactional
public class TtsPlaybackService {

    private final TtsPlaybackPositionRepository positionRepository;
    private final BookRepository bookRepository;
    private final BookFileRepository bookFileRepository;
    private final SyncChangePublisher changePublisher;

    public TtsPlaybackService(
            TtsPlaybackPositionRepository positionRepository,
            BookRepository bookRepository,
            BookFileRepository bookFileRepository) {
        this(positionRepository, bookRepository, bookFileRepository, null);
    }

    @Autowired
    public TtsPlaybackService(
            TtsPlaybackPositionRepository positionRepository,
            BookRepository bookRepository,
            BookFileRepository bookFileRepository,
            @Autowired(required = false) SyncChangePublisher changePublisher) {
        this.positionRepository = positionRepository;
        this.bookRepository = bookRepository;
        this.bookFileRepository = bookFileRepository;
        this.changePublisher = changePublisher;
    }

    public TtsPositionResponse saveOrUpdate(
            UUID userId, UUID bookId, UUID fileId, SaveTtsPositionRequest request) {

        Book book = getOwnedBook(bookId, userId);
        BookFile file = getBookFile(fileId, bookId);
        validateTtsFormat(file);

        if (request.chapterIndex() < 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Chapter index cannot be negative");
        }

        if (request.chunkIndex() < 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Chunk index cannot be negative");
        }

        if (request.characterOffset() < 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Character offset cannot be negative");
        }

        if (request.progressPercentage() != null &&
                (request.progressPercentage().compareTo(java.math.BigDecimal.ZERO) < 0 ||
                 request.progressPercentage().compareTo(new java.math.BigDecimal("100.00")) > 0)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Progress percentage must be between 0 and 100");
        }

        TtsPlaybackPosition position = positionRepository
                .findByBook_IdAndBookFile_Id(bookId, fileId)
                .orElseGet(() -> {
                    TtsPlaybackPosition p = new TtsPlaybackPosition();
                    p.setBook(book);
                    p.setBookFile(file);
                    return p;
                });

        position.setChapterIndex(request.chapterIndex());
        position.setChunkIndex(request.chunkIndex());
        position.setCharacterOffset(request.characterOffset());
        position.setProgressPercentage(request.progressPercentage());
        position.setUpdatedAt(OffsetDateTime.now());

        TtsPlaybackPosition saved = positionRepository.save(position);

        // Update last read time for the book
        book.setLastReadAt(OffsetDateTime.now());
        bookRepository.save(book);

        TtsPositionResponse response = toResponse(saved);
        if (changePublisher != null) {
            changePublisher.publishUpdate(userId, "TTS_POSITION", saved.getId().toString(), 1L, response);
        }
        return response;
    }

    @Transactional(readOnly = true)
    public Optional<TtsPositionResponse> getPosition(UUID userId, UUID bookId, UUID fileId) {
        getOwnedBook(bookId, userId);
        getBookFile(fileId, bookId);

        return positionRepository
                .findByBook_IdAndBookFile_Id(bookId, fileId)
                .map(this::toResponse);
    }

    public void resetPosition(UUID userId, UUID bookId, UUID fileId) {
        getOwnedBook(bookId, userId);
        getBookFile(fileId, bookId);

        positionRepository.deleteByBook_IdAndBookFile_Id(bookId, fileId);
        if (changePublisher != null) {
            changePublisher.publishDelete(userId, "TTS_POSITION", bookId + ":" + fileId, 1L);
        }
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
                        HttpStatus.NOT_FOUND, "File not found for this book"));
    }

    private void validateTtsFormat(BookFile file) {
        String format = file.getFileFormat();
        if (format == null || (!format.equalsIgnoreCase("PDF") &&
                !format.equalsIgnoreCase("EPUB") &&
                !format.equalsIgnoreCase("DOCX"))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "File format is not supported for TTS (PDF, EPUB, DOCX)");
        }
    }

    private TtsPositionResponse toResponse(TtsPlaybackPosition p) {
        return new TtsPositionResponse(
                p.getId(),
                p.getBook().getId(),
                p.getBookFile().getId(),
                p.getChapterIndex(),
                p.getChunkIndex(),
                p.getCharacterOffset(),
                p.getProgressPercentage(),
                p.getUpdatedAt()
        );
    }
}
