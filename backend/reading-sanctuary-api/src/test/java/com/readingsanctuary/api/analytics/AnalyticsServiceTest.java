package com.readingsanctuary.api.analytics;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import com.readingsanctuary.api.analytics.dto.*;
import com.readingsanctuary.api.analytics.entity.ReadingActivitySession;
import com.readingsanctuary.api.analytics.enums.ActivityType;
import com.readingsanctuary.api.analytics.repository.ReadingActivitySessionRepository;
import com.readingsanctuary.api.analytics.service.AnalyticsService;
import com.readingsanctuary.api.analytics.service.ReadingStreakService;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.user.entity.User;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AnalyticsServiceTest {

    @Mock
    private BookRepository bookRepository;

    @Mock
    private ReadingActivitySessionRepository sessionRepository;

    @Mock
    private ReadingStreakService streakService;

    @InjectMocks
    private AnalyticsService analyticsService;

    private UUID userId;
    private User user;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        user = new User("test@example.com", "hash");
        ReflectionTestUtils.setField(user, "id", userId);
    }

    @Test
    void getOverview_ReturnsCorrectAggregates() {
        when(bookRepository.countByCreatedBy_Id(userId)).thenReturn(100L);
        when(bookRepository.countByCreatedBy_IdAndReadingStatus(userId, ReadingStatus.COMPLETED)).thenReturn(40L);
        when(bookRepository.countByCreatedBy_IdAndReadingStatus(userId, ReadingStatus.CURRENTLY_READING)).thenReturn(5L);
        when(bookRepository.countByCreatedBy_IdAndReadingStatus(userId, ReadingStatus.TO_READ)).thenReturn(50L);
        when(bookRepository.countByCreatedBy_IdAndReadingStatus(userId, ReadingStatus.DNF)).thenReturn(5L);

        when(sessionRepository.sumDurationByActivityType(eq(userId), any(), any())).thenReturn(List.of(
                new Object[]{ActivityType.READING, 60000L},    // 1000 mins
                new Object[]{ActivityType.AUDIOBOOK, 12000L},  // 200 mins
                new Object[]{ActivityType.TTS, 6000L}          // 100 mins
        ));
        when(sessionRepository.sumPagesAdvanced(eq(userId), any(), any())).thenReturn(450);

        when(streakService.calculateStreaks(eq(userId), any())).thenReturn(
                new StreakResponse(5, 12, LocalDate.now().minusDays(4), LocalDate.now(), Collections.emptyList())
        );

        AnalyticsOverviewResponse overview = analyticsService.getOverview(
                userId, LocalDate.of(2026, 1, 1), LocalDate.of(2026, 12, 31), ZoneOffset.UTC);

        assertThat(overview.totalBooks()).isEqualTo(100L);
        assertThat(overview.completedBooks()).isEqualTo(40L);
        assertThat(overview.currentlyReading()).isEqualTo(5L);
        assertThat(overview.readingMinutes()).isEqualTo(1000L);
        assertThat(overview.audiobookMinutes()).isEqualTo(200L);
        assertThat(overview.ttsMinutes()).isEqualTo(100L);
        assertThat(overview.pagesAdvanced()).isEqualTo(450L);
        assertThat(overview.currentStreak()).isEqualTo(5);
        assertThat(overview.longestStreak()).isEqualTo(12);
    }

    @Test
    void getActivity_BuildsDailySeriesProperly() {
        LocalDate date = LocalDate.of(2026, 11, 5);
        OffsetDateTime dt = date.atTime(10, 0).atOffset(ZoneOffset.UTC);

        ReadingActivitySession s1 = new ReadingActivitySession();
        s1.setUser(user);
        s1.setActivityType(ActivityType.READING);
        s1.setStartedAt(dt);
        s1.setDurationSeconds(1800); // 30 mins
        s1.setPagesAdvanced(15);

        when(sessionRepository.findAllByUser_IdAndStartedAtBetweenOrderByStartedAtAsc(eq(userId), any(), any()))
                .thenReturn(List.of(s1));

        ActivitySummaryResponse summary = analyticsService.getActivity(
                userId, "MONTH", 2026, 11, ZoneOffset.UTC);

        assertThat(summary.period()).isEqualTo("MONTH");
        assertThat(summary.year()).isEqualTo(2026);
        assertThat(summary.activities()).isNotEmpty();

        DailyActivityResponse day5 = summary.activities().stream()
                .filter(a -> a.date().equals(date))
                .findFirst()
                .orElse(null);

        assertThat(day5).isNotNull();
        assertThat(day5.readingMinutes()).isEqualTo(30);
        assertThat(day5.pagesAdvanced()).isEqualTo(15);
        assertThat(day5.active()).isTrue();
    }

    @Test
    void getGenres_CalculatesPercentagesCorrectly() {
        when(bookRepository.countCompletedBooksBetween(eq(userId), any(), any())).thenReturn(20L);
        when(bookRepository.countCompletedBooksByGenre(eq(userId), any(), any())).thenReturn(List.of(
                new Object[]{"Fantasy", 10L},
                new Object[]{"Sci-Fi", 5L}
        ));

        GenreAnalyticsResponse response = analyticsService.getGenres(userId, 2026);

        assertThat(response.genres()).hasSize(2);
        assertThat(response.genres().get(0).genre()).isEqualTo("Fantasy");
        assertThat(response.genres().get(0).booksCompleted()).isEqualTo(10L);
        assertThat(response.genres().get(0).percentage()).isEqualTo(50.0);
    }

    @Test
    void getListening_SeparatesAudiobookAndTts() {
        when(sessionRepository.sumDurationByActivityType(eq(userId), any(), any())).thenReturn(List.of(
                new Object[]{ActivityType.AUDIOBOOK, 36000L}, // 600 mins
                new Object[]{ActivityType.TTS, 18000L}        // 300 mins
        ));
        when(sessionRepository.countSessionsByActivityType(eq(userId), any(), any())).thenReturn(List.of(
                new Object[]{ActivityType.AUDIOBOOK, 15L},
                new Object[]{ActivityType.TTS, 8L}
        ));

        ListeningAnalyticsResponse response = analyticsService.getListening(userId, 2026);

        assertThat(response.audiobook().totalMinutes()).isEqualTo(600L);
        assertThat(response.audiobook().sessions()).isEqualTo(15L);
        assertThat(response.tts().totalMinutes()).isEqualTo(300L);
        assertThat(response.tts().sessions()).isEqualTo(8L);
        assertThat(response.combinedListeningMinutes()).isEqualTo(900L);
    }
}
