package com.readingsanctuary.api.audiobook.service;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.audiobook.dto.AudioPositionResponse;
import com.readingsanctuary.api.audiobook.dto.SaveAudioPositionRequest;
import com.readingsanctuary.api.audiobook.entity.AudiobookPlaybackPosition;
import com.readingsanctuary.api.audiobook.repository.AudiobookPlaybackPositionRepository;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.sync.service.SyncChangePublisher;
import org.springframework.beans.factory.annotation.Autowired;

@Service
@Transactional
public class AudiobookPlaybackService {

    private final AudiobookPlaybackPositionRepository positionRepository;
    private final BookRepository bookRepository;
    private final BookFileRepository bookFileRepository;
    private final SyncChangePublisher changePublisher;

    public AudiobookPlaybackService(
            AudiobookPlaybackPositionRepository positionRepository,
            BookRepository bookRepository,
            BookFileRepository bookFileRepository) {
        this(positionRepository, bookRepository, bookFileRepository, null);
    }

    @Autowired
    public AudiobookPlaybackService(
            AudiobookPlaybackPositionRepository positionRepository,
            BookRepository bookRepository,
            BookFileRepository bookFileRepository,
            @Autowired(required = false) SyncChangePublisher changePublisher) {
        this.positionRepository = positionRepository;
        this.bookRepository = bookRepository;
        this.bookFileRepository = bookFileRepository;
        this.changePublisher = changePublisher;
    }

    public AudioPositionResponse saveOrUpdate(
            UUID userId, UUID bookId, UUID fileId, SaveAudioPositionRequest request) {

        Book book = getOwnedBook(bookId, userId);
        BookFile file = getBookFile(fileId, bookId);
        validateAudioFormat(file);

        if (request.positionMs() < 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Position cannot be negative");
        }

        if (request.durationMs() < 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Duration cannot be negative");
        }

        if (request.playbackSpeed() != null &&
                (request.playbackSpeed().compareTo(new java.math.BigDecimal("0.50")) < 0 ||
                 request.playbackSpeed().compareTo(new java.math.BigDecimal("3.00")) > 0)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Playback speed must be between 0.50 and 3.00");
        }

        if (request.durationMs() > 0 && request.positionMs() > request.durationMs()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Position cannot exceed duration");
        }

        AudiobookPlaybackPosition position = positionRepository
                .findByBook_IdAndBookFile_Id(bookId, fileId)
                .orElseGet(() -> {
                    AudiobookPlaybackPosition p = new AudiobookPlaybackPosition();
                    p.setBook(book);
                    p.setBookFile(file);
                    return p;
                });

        position.setPositionMs(request.positionMs());
        position.setDurationMs(request.durationMs());
        position.setPlaybackSpeed(request.playbackSpeed());

        boolean completed = Boolean.TRUE.equals(request.isCompleted()) ||
                (request.durationMs() > 0 && request.positionMs() >= request.durationMs());
        position.setCompleted(completed);
        position.setUpdatedAt(OffsetDateTime.now());

        AudiobookPlaybackPosition saved = positionRepository.save(position);

        // Update last read time for the book
        book.setLastReadAt(OffsetDateTime.now());
        bookRepository.save(book);

        AudioPositionResponse response = toResponse(saved);
        if (changePublisher != null) {
            changePublisher.publishUpdate(userId, "AUDIO_POSITION", saved.getId().toString(), 1L, response);
        }
        return response;
    }

    @Transactional(readOnly = true)
    public Optional<AudioPositionResponse> getPosition(UUID userId, UUID bookId, UUID fileId) {
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
            changePublisher.publishDelete(userId, "AUDIO_POSITION", bookId + ":" + fileId, 1L);
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

    private void validateAudioFormat(BookFile file) {
        String format = file.getFileFormat();
        if (format == null || (!format.equalsIgnoreCase("MP3") && !format.equalsIgnoreCase("M4B") && !format.equalsIgnoreCase("M4A"))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "File is not a supported audio format (MP3, M4B, M4A)");
        }
    }

    private AudioPositionResponse toResponse(AudiobookPlaybackPosition p) {
        return new AudioPositionResponse(
                p.getId(),
                p.getBook().getId(),
                p.getBookFile().getId(),
                p.getPositionMs(),
                p.getDurationMs(),
                p.getPlaybackSpeed(),
                p.isCompleted(),
                p.getUpdatedAt()
        );
    }
}
