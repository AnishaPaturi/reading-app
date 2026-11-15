package com.readingsanctuary.api.readingprogress.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.readingprogress.dto.ReadingProgressRequest;
import com.readingsanctuary.api.readingprogress.dto.ReadingProgressResponse;
import com.readingsanctuary.api.readingprogress.entity.ReadingProgress;
import com.readingsanctuary.api.readingprogress.repository.ReadingProgressRepository;
import com.readingsanctuary.api.sync.service.SyncChangePublisher;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
@Transactional
public class ReadingProgressService {

    private final ReadingProgressRepository progressRepository;
    private final BookFileRepository bookFileRepository;
    private final BookRepository bookRepository;
    private final UserRepository userRepository;
    private final SyncChangePublisher changePublisher;

    public ReadingProgressService(
            ReadingProgressRepository progressRepository,
            BookFileRepository bookFileRepository,
            BookRepository bookRepository,
            UserRepository userRepository) {
        this(progressRepository, bookFileRepository, bookRepository, userRepository, null);
    }

    @Autowired
    public ReadingProgressService(
            ReadingProgressRepository progressRepository,
            BookFileRepository bookFileRepository,
            BookRepository bookRepository,
            UserRepository userRepository,
            @Autowired(required = false) SyncChangePublisher changePublisher) {
        this.progressRepository = progressRepository;
        this.bookFileRepository = bookFileRepository;
        this.bookRepository = bookRepository;
        this.userRepository = userRepository;
        this.changePublisher = changePublisher;
    }

    @Transactional(readOnly = true)
    public Optional<ReadingProgressResponse> getProgress(UUID userId, UUID bookFileId) {
        verifyBookFileOwnership(userId, bookFileId);
        return progressRepository.findByUserIdAndBookFileId(userId, bookFileId)
                .map(this::toResponse);
    }

    public ReadingProgressResponse saveProgress(UUID userId, UUID bookFileId, ReadingProgressRequest request) {
        BookFile file = verifyBookFileOwnership(userId, bookFileId);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        Book book = file.getBook();

        ReadingProgress progress = progressRepository.findByUserIdAndBookFileId(userId, bookFileId)
                .orElseGet(() -> {
                    ReadingProgress p = new ReadingProgress();
                    p.setUser(user);
                    p.setBookFile(file);
                    return p;
                });

        // Conflict check: if incoming update is older than existing clientUpdatedAt, ignore outdated sync
        if (request.clientUpdatedAt() != null && progress.getClientUpdatedAt() != null) {
            if (request.clientUpdatedAt().isBefore(progress.getClientUpdatedAt())) {
                return toResponse(progress);
            }
        }

        String format = request.format() != null && !request.format().isBlank()
                ? request.format().toUpperCase()
                : file.getFileFormat();

        progress.setFormat(format);
        if (request.currentPage() != null) {
            progress.setCurrentPage(request.currentPage());
        }
        if (request.totalPages() != null) {
            progress.setTotalPages(request.totalPages());
        }
        if (request.chapterHref() != null) {
            progress.setChapterHref(request.chapterHref());
        }
        if (request.epubCfi() != null) {
            progress.setEpubCfi(request.epubCfi());
        }
        if (request.audioPositionMs() != null) {
            progress.setAudioPositionMs(request.audioPositionMs());
        }
        if (request.audioDurationMs() != null) {
            progress.setAudioDurationMs(request.audioDurationMs());
        }
        if (request.progressPercentage() != null) {
            progress.setProgressPercentage(request.progressPercentage());
        } else if (progress.getCurrentPage() != null && progress.getTotalPages() != null && progress.getTotalPages() > 0) {
            double pct = ((double) progress.getCurrentPage() / progress.getTotalPages()) * 100.0;
            progress.setProgressPercentage(BigDecimal.valueOf(Math.min(100.0, Math.max(0.0, pct))));
        }

        if (request.positionData() != null && !request.positionData().isBlank()) {
            progress.setPositionData(request.positionData());
        }

        progress.setClientUpdatedAt(request.clientUpdatedAt() != null ? request.clientUpdatedAt() : OffsetDateTime.now());
        progress.setLastOpenedAt(OffsetDateTime.now());
        progress.setUpdatedAt(OffsetDateTime.now());

        ReadingProgress saved = progressRepository.save(progress);

        // Synchronize with Book reading status
        book.setLastReadAt(OffsetDateTime.now());
        if (book.getReadingStatus() == ReadingStatus.TO_READ) {
            book.setReadingStatus(ReadingStatus.CURRENTLY_READING);
            if (book.getStartedAt() == null) {
                book.setStartedAt(LocalDate.now());
            }
        }
        if (saved.getCurrentPage() != null) {
            book.setCurrentPage(saved.getCurrentPage());
        }
        if (saved.getTotalPages() != null) {
            book.setTotalPages(saved.getTotalPages());
        }
        bookRepository.save(book);

        ReadingProgressResponse response = toResponse(saved);
        if (changePublisher != null) {
            changePublisher.publishUpdate(userId, "READING_PROGRESS", saved.getId().toString(), 1L, response);
        }

        return response;
    }

    @Transactional(readOnly = true)
    public List<ReadingProgressResponse> getAllProgress(UUID userId) {
        return progressRepository.findAllByUserIdOrderByUpdatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public void resetProgress(UUID userId, UUID bookFileId) {
        verifyBookFileOwnership(userId, bookFileId);
        progressRepository.deleteByUserIdAndBookFileId(userId, bookFileId);
        if (changePublisher != null) {
            changePublisher.publishDelete(userId, "READING_PROGRESS", bookFileId.toString(), 1L);
        }
    }

    private BookFile verifyBookFileOwnership(UUID userId, UUID bookFileId) {
        BookFile file = bookFileRepository.findById(bookFileId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Book file not found"));

        Book book = file.getBook();
        if (book == null || !book.getCreatedBy().getId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied to book file");
        }
        return file;
    }

    private ReadingProgressResponse toResponse(ReadingProgress p) {
        return new ReadingProgressResponse(
                p.getId(),
                p.getUser().getId(),
                p.getBookFile().getBook() != null ? p.getBookFile().getBook().getId() : null,
                p.getBookFile().getId(),
                p.getFormat(),
                p.getCurrentPage(),
                p.getTotalPages(),
                p.getChapterHref(),
                p.getEpubCfi(),
                p.getAudioPositionMs(),
                p.getAudioDurationMs(),
                p.getProgressPercentage(),
                p.getPositionData(),
                p.getLastOpenedAt(),
                p.getClientUpdatedAt(),
                p.getCreatedAt(),
                p.getUpdatedAt()
        );
    }
}
