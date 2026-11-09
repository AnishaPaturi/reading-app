package com.readingsanctuary.api.analytics;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.analytics.dto.ActivityHeartbeatRequest;
import com.readingsanctuary.api.analytics.dto.ActivitySessionRequest;
import com.readingsanctuary.api.analytics.dto.ActivitySessionResponse;
import com.readingsanctuary.api.analytics.dto.CloseSessionRequest;
import com.readingsanctuary.api.analytics.entity.ReadingActivitySession;
import com.readingsanctuary.api.analytics.enums.ActivityType;
import com.readingsanctuary.api.analytics.repository.ReadingActivitySessionRepository;
import com.readingsanctuary.api.analytics.service.ActivitySessionService;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ActivitySessionServiceTest {

    @Mock
    private ReadingActivitySessionRepository sessionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @InjectMocks
    private ActivitySessionService sessionService;

    private UUID userId;
    private UUID bookId;
    private UUID fileId;
    private User user;
    private Book book;
    private BookFile pdfFile;
    private BookFile mp3File;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        bookId = UUID.randomUUID();
        fileId = UUID.randomUUID();

        user = new User("test@example.com", "hash");
        ReflectionTestUtils.setField(user, "id", userId);

        book = new Book();
        ReflectionTestUtils.setField(book, "id", bookId);

        pdfFile = new BookFile();
        ReflectionTestUtils.setField(pdfFile, "id", fileId);
        pdfFile.setBook(book);
        pdfFile.setFileFormat("PDF");

        mp3File = new BookFile();
        ReflectionTestUtils.setField(mp3File, "id", fileId);
        mp3File.setBook(book);
        mp3File.setFileFormat("MP3");
    }

    @Test
    void startSession_Success() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(pdfFile));
        when(sessionRepository.findByUser_IdAndIsActiveTrue(userId)).thenReturn(List.of());

        when(sessionRepository.save(any(ReadingActivitySession.class))).thenAnswer(inv -> {
            ReadingActivitySession s = inv.getArgument(0);
            ReflectionTestUtils.setField(s, "id", UUID.randomUUID());
            return s;
        });

        ActivitySessionRequest request = new ActivitySessionRequest(
                bookId, fileId, ActivityType.READING, 10.0
        );

        ActivitySessionResponse response = sessionService.startSession(userId, request);

        assertThat(response).isNotNull();
        assertThat(response.userId()).isEqualTo(userId);
        assertThat(response.bookId()).isEqualTo(bookId);
        assertThat(response.activityType()).isEqualTo(ActivityType.READING);
        assertThat(response.isActive()).isTrue();
        assertThat(response.startProgress()).isEqualTo(10.0);
    }

    @Test
    void startSession_ClosesExistingActiveSessions() {
        ReadingActivitySession oldSession = new ReadingActivitySession();
        ReflectionTestUtils.setField(oldSession, "id", UUID.randomUUID());
        oldSession.setUser(user);
        oldSession.setActive(true);
        oldSession.setLastHeartbeatAt(OffsetDateTime.now().minusSeconds(40));

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(pdfFile));
        when(sessionRepository.findByUser_IdAndIsActiveTrue(userId)).thenReturn(List.of(oldSession));

        when(sessionRepository.save(any(ReadingActivitySession.class))).thenAnswer(inv -> {
            ReadingActivitySession s = inv.getArgument(0);
            if (s.getId() == null) {
                ReflectionTestUtils.setField(s, "id", UUID.randomUUID());
            }
            return s;
        });

        ActivitySessionRequest request = new ActivitySessionRequest(
                bookId, fileId, ActivityType.READING, 0.0
        );

        sessionService.startSession(userId, request);

        assertThat(oldSession.isActive()).isFalse();
        assertThat(oldSession.getEndedAt()).isNotNull();
    }

    @Test
    void startSession_InvalidFileFormatForActivity_ThrowsBadRequest() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(mp3File));

        ActivitySessionRequest request = new ActivitySessionRequest(
                bookId, fileId, ActivityType.READING, 0.0
        );

        assertThatThrownBy(() -> sessionService.startSession(userId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void heartbeat_Success_CreditsDurationCappedAtMax() {
        UUID sessionId = UUID.randomUUID();
        ReadingActivitySession session = new ReadingActivitySession();
        ReflectionTestUtils.setField(session, "id", sessionId);
        session.setUser(user);
        session.setActive(true);
        session.setDurationSeconds(50);
        // heartbeat arrived 120 seconds later (should be capped at MAX_CREDITED_INTERVAL_SECONDS = 60)
        session.setLastHeartbeatAt(OffsetDateTime.now().minusSeconds(120));

        when(sessionRepository.findByIdAndUser_Id(sessionId, userId)).thenReturn(Optional.of(session));
        when(sessionRepository.save(any(ReadingActivitySession.class))).thenAnswer(inv -> inv.getArgument(0));

        ActivityHeartbeatRequest request = new ActivityHeartbeatRequest(15.0, 3);
        ActivitySessionResponse response = sessionService.heartbeat(userId, sessionId, request);

        assertThat(response.durationSeconds()).isEqualTo(50 + ActivitySessionService.MAX_CREDITED_INTERVAL_SECONDS);
        assertThat(response.pagesAdvanced()).isEqualTo(3);
        assertThat(response.endProgress()).isEqualTo(15.0);
    }

    @Test
    void heartbeat_ClosedSession_ThrowsBadRequest() {
        UUID sessionId = UUID.randomUUID();
        ReadingActivitySession session = new ReadingActivitySession();
        session.setUser(user);
        session.setActive(false);

        when(sessionRepository.findByIdAndUser_Id(sessionId, userId)).thenReturn(Optional.of(session));

        ActivityHeartbeatRequest request = new ActivityHeartbeatRequest(15.0, 1);
        assertThatThrownBy(() -> sessionService.heartbeat(userId, sessionId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void closeSession_IsIdempotent() {
        UUID sessionId = UUID.randomUUID();
        ReadingActivitySession session = new ReadingActivitySession();
        ReflectionTestUtils.setField(session, "id", sessionId);
        session.setUser(user);
        session.setActive(false);
        session.setDurationSeconds(100);

        when(sessionRepository.findByIdAndUser_Id(sessionId, userId)).thenReturn(Optional.of(session));

        ActivitySessionResponse response = sessionService.closeSession(userId, sessionId, new CloseSessionRequest(20.0));

        assertThat(response.isActive()).isFalse();
        assertThat(response.durationSeconds()).isEqualTo(100);
        verify(sessionRepository, never()).save(any());
    }
}
