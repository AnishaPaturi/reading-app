package com.readingsanctuary.api.analytics.service;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.analytics.dto.ActivityHeartbeatRequest;
import com.readingsanctuary.api.analytics.dto.ActivitySessionRequest;
import com.readingsanctuary.api.analytics.dto.ActivitySessionResponse;
import com.readingsanctuary.api.analytics.dto.CloseSessionRequest;
import com.readingsanctuary.api.analytics.entity.ReadingActivitySession;
import com.readingsanctuary.api.analytics.enums.ActivityType;
import com.readingsanctuary.api.analytics.repository.ReadingActivitySessionRepository;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
@Transactional
public class ActivitySessionService {

    public static final int MAX_CREDITED_INTERVAL_SECONDS = 60;
    private static final Set<String> READING_FORMATS = Set.of("pdf", "epub", "docx");
    private static final Set<String> AUDIOBOOK_FORMATS = Set.of("mp3", "m4b", "m4a");
    private static final Set<String> TTS_FORMATS = Set.of("pdf", "epub", "docx");

    private final ReadingActivitySessionRepository sessionRepository;
    private final UserRepository userRepository;
    private final BookRepository bookRepository;
    private final BookFileRepository bookFileRepository;

    public ActivitySessionService(
            ReadingActivitySessionRepository sessionRepository,
            UserRepository userRepository,
            BookRepository bookRepository,
            BookFileRepository bookFileRepository) {
        this.sessionRepository = sessionRepository;
        this.userRepository = userRepository;
        this.bookRepository = bookRepository;
        this.bookFileRepository = bookFileRepository;
    }

    public ActivitySessionResponse startSession(UUID userId, ActivitySessionRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        if (request.progress() != null && request.progress() < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Progress cannot be negative");
        }

        Book book = null;
        if (request.bookId() != null) {
            book = bookRepository.findByIdAndCreatedBy_Id(request.bookId(), userId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Book not found"));
        }

        BookFile file = null;
        if (request.bookFileId() != null) {
            if (book == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "bookId is required when bookFileId is provided");
            }
            file = bookFileRepository.findByIdAndBook_Id(request.bookFileId(), book.getId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Book file not found"));
            validateFileFormatForActivity(file, request.activityType());
        }

        // Close any stale active sessions for this user
        closeActiveSessionsForUser(userId);

        OffsetDateTime now = OffsetDateTime.now();
        ReadingActivitySession session = new ReadingActivitySession();
        session.setUser(user);
        session.setBook(book);
        session.setBookFile(file);
        session.setActivityType(request.activityType());
        session.setStartedAt(now);
        session.setLastHeartbeatAt(now);
        session.setStartProgress(request.progress());
        session.setEndProgress(request.progress());
        session.setActive(true);
        session.setDurationSeconds(0);
        session.setPagesAdvanced(0);

        ReadingActivitySession saved = sessionRepository.save(session);
        return toResponse(saved);
    }

    public ActivitySessionResponse heartbeat(UUID userId, UUID sessionId, ActivityHeartbeatRequest request) {
        ReadingActivitySession session = sessionRepository.findByIdAndUser_Id(sessionId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));

        if (!session.isActive()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Session is already closed");
        }

        if (request.progress() != null && request.progress() < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Progress cannot be negative");
        }

        if (request.pagesAdvanced() != null && request.pagesAdvanced() < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Pages advanced cannot be negative");
        }

        OffsetDateTime now = OffsetDateTime.now();
        long secondsSinceLastHeartbeat = Duration.between(session.getLastHeartbeatAt(), now).getSeconds();
        if (secondsSinceLastHeartbeat < 0) {
            secondsSinceLastHeartbeat = 0;
        }

        // Credit at most MAX_CREDITED_INTERVAL_SECONDS
        long creditedSeconds = Math.min(secondsSinceLastHeartbeat, MAX_CREDITED_INTERVAL_SECONDS);
        session.setDurationSeconds(session.getDurationSeconds() + (int) creditedSeconds);
        session.setLastHeartbeatAt(now);

        if (request.progress() != null) {
            session.setEndProgress(request.progress());
        }

        if (request.pagesAdvanced() != null && request.pagesAdvanced() > 0) {
            session.setPagesAdvanced(session.getPagesAdvanced() + request.pagesAdvanced());
        }

        ReadingActivitySession updated = sessionRepository.save(session);
        return toResponse(updated);
    }

    public ActivitySessionResponse closeSession(UUID userId, UUID sessionId, CloseSessionRequest request) {
        ReadingActivitySession session = sessionRepository.findByIdAndUser_Id(sessionId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));

        if (!session.isActive()) {
            // Idempotent: return already closed session
            return toResponse(session);
        }

        if (request != null && request.progress() != null && request.progress() < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Progress cannot be negative");
        }

        OffsetDateTime now = OffsetDateTime.now();
        long secondsSinceLastHeartbeat = Duration.between(session.getLastHeartbeatAt(), now).getSeconds();
        if (secondsSinceLastHeartbeat < 0) {
            secondsSinceLastHeartbeat = 0;
        }

        long creditedSeconds = Math.min(secondsSinceLastHeartbeat, MAX_CREDITED_INTERVAL_SECONDS);
        session.setDurationSeconds(session.getDurationSeconds() + (int) creditedSeconds);
        session.setLastHeartbeatAt(now);
        session.setEndedAt(now);
        session.setActive(false);

        if (request != null && request.progress() != null) {
            session.setEndProgress(request.progress());
        }

        ReadingActivitySession saved = sessionRepository.save(session);
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<ActivitySessionResponse> getSessionHistory(UUID userId) {
        return sessionRepository.findAllByUser_IdOrderByStartedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    private void closeActiveSessionsForUser(UUID userId) {
        List<ReadingActivitySession> activeSessions = sessionRepository.findByUser_IdAndIsActiveTrue(userId);
        OffsetDateTime now = OffsetDateTime.now();
        for (ReadingActivitySession active : activeSessions) {
            long gap = Duration.between(active.getLastHeartbeatAt(), now).getSeconds();
            if (gap > 0) {
                long credited = Math.min(gap, MAX_CREDITED_INTERVAL_SECONDS);
                active.setDurationSeconds(active.getDurationSeconds() + (int) credited);
            }
            active.setEndedAt(now);
            active.setActive(false);
            sessionRepository.save(active);
        }
    }

    private void validateFileFormatForActivity(BookFile file, ActivityType activityType) {
        String format = file.getFileFormat() != null ? file.getFileFormat().toLowerCase(Locale.ROOT) : "";
        boolean valid = switch (activityType) {
            case READING -> READING_FORMATS.contains(format);
            case AUDIOBOOK -> AUDIOBOOK_FORMATS.contains(format);
            case TTS -> TTS_FORMATS.contains(format);
        };

        if (!valid) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "File format " + file.getFileFormat() + " is not valid for activity type " + activityType
            );
        }
    }

    public ActivitySessionResponse toResponse(ReadingActivitySession s) {
        return new ActivitySessionResponse(
                s.getId(),
                s.getUser().getId(),
                s.getBook() != null ? s.getBook().getId() : null,
                s.getBookFile() != null ? s.getBookFile().getId() : null,
                s.getActivityType(),
                s.getStartedAt(),
                s.getEndedAt(),
                s.getLastHeartbeatAt(),
                s.getDurationSeconds(),
                s.getStartProgress(),
                s.getEndProgress(),
                s.getPagesAdvanced(),
                s.isActive(),
                s.getCreatedAt(),
                s.getUpdatedAt()
        );
    }
}
