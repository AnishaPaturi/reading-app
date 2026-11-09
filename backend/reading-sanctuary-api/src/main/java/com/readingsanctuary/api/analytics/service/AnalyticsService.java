package com.readingsanctuary.api.analytics.service;

import java.time.LocalDate;
import java.time.Month;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.TextStyle;
import java.util.*;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.analytics.dto.*;
import com.readingsanctuary.api.analytics.entity.ReadingActivitySession;
import com.readingsanctuary.api.analytics.enums.ActivityType;
import com.readingsanctuary.api.analytics.repository.ReadingActivitySessionRepository;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.book.repository.BookRepository;

@Service
@Transactional(readOnly = true)
public class AnalyticsService {

    private final BookRepository bookRepository;
    private final ReadingActivitySessionRepository sessionRepository;
    private final ReadingStreakService streakService;

    public AnalyticsService(
            BookRepository bookRepository,
            ReadingActivitySessionRepository sessionRepository,
            ReadingStreakService streakService) {
        this.bookRepository = bookRepository;
        this.sessionRepository = sessionRepository;
        this.streakService = streakService;
    }

    public AnalyticsOverviewResponse getOverview(UUID userId, LocalDate from, LocalDate to, ZoneId zoneId) {
        ZoneId zone = (zoneId != null) ? zoneId : ZoneOffset.UTC;

        long totalBooks = bookRepository.countByCreatedBy_Id(userId);
        long completed = bookRepository.countByCreatedBy_IdAndReadingStatus(userId, ReadingStatus.COMPLETED);
        long currentlyReading = bookRepository.countByCreatedBy_IdAndReadingStatus(userId, ReadingStatus.CURRENTLY_READING);
        long toRead = bookRepository.countByCreatedBy_IdAndReadingStatus(userId, ReadingStatus.TO_READ);
        long dnf = bookRepository.countByCreatedBy_IdAndReadingStatus(userId, ReadingStatus.DNF);

        OffsetDateTime startOffset = (from != null)
                ? from.atStartOfDay(zone).toOffsetDateTime()
                : LocalDate.of(1970, 1, 1).atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime endOffset = (to != null)
                ? to.plusDays(1).atStartOfDay(zone).toOffsetDateTime().minusNanos(1)
                : LocalDate.of(2099, 12, 31).atStartOfDay(zone).toOffsetDateTime();

        List<Object[]> durationRows = sessionRepository.sumDurationByActivityType(userId, startOffset, endOffset);
        long readingMinutes = 0;
        long audiobookMinutes = 0;
        long ttsMinutes = 0;
        for (Object[] row : durationRows) {
            ActivityType type = (ActivityType) row[0];
            long mins = ((Number) row[1]).longValue() / 60;
            switch (type) {
                case READING -> readingMinutes += mins;
                case AUDIOBOOK -> audiobookMinutes += mins;
                case TTS -> ttsMinutes += mins;
            }
        }

        long pagesAdvanced = sessionRepository.sumPagesAdvanced(userId, startOffset, endOffset);

        StreakResponse streaks = streakService.calculateStreaks(userId, zone);

        return new AnalyticsOverviewResponse(
                totalBooks,
                completed,
                currentlyReading,
                toRead,
                dnf,
                readingMinutes,
                audiobookMinutes,
                ttsMinutes,
                pagesAdvanced,
                streaks.currentStreak(),
                streaks.longestStreak()
        );
    }

    public ActivitySummaryResponse getActivity(
            UUID userId, String period, Integer targetYear, Integer targetMonth, ZoneId zoneId) {

        ZoneId zone = (zoneId != null) ? zoneId : ZoneOffset.UTC;
        LocalDate now = LocalDate.now(zone);
        int year = (targetYear != null) ? targetYear : now.getYear();
        String periodUpper = (period != null) ? period.toUpperCase(Locale.ROOT) : "MONTH";

        LocalDate startDate;
        LocalDate endDate;

        switch (periodUpper) {
            case "WEEK" -> {
                startDate = now.minusDays(6);
                endDate = now;
            }
            case "YEAR" -> {
                startDate = LocalDate.of(year, 1, 1);
                endDate = LocalDate.of(year, 12, 31);
            }
            default -> { // MONTH
                int month = (targetMonth != null) ? targetMonth : now.getMonthValue();
                startDate = LocalDate.of(year, month, 1);
                endDate = startDate.withDayOfMonth(startDate.lengthOfMonth());
            }
        }

        OffsetDateTime startOffset = startDate.atStartOfDay(zone).toOffsetDateTime();
        OffsetDateTime endOffset = endDate.plusDays(1).atStartOfDay(zone).toOffsetDateTime().minusNanos(1);

        List<ReadingActivitySession> sessions =
                sessionRepository.findAllByUser_IdAndStartedAtBetweenOrderByStartedAtAsc(userId, startOffset, endOffset);

        // Group by calendar date
        Map<LocalDate, long[]> dateAggregates = new HashMap<>(); // [readingSec, audioSec, ttsSec, pages]
        for (ReadingActivitySession s : sessions) {
            LocalDate d = s.getStartedAt().atZoneSameInstant(zone).toLocalDate();
            long[] agg = dateAggregates.computeIfAbsent(d, k -> new long[4]);
            switch (s.getActivityType()) {
                case READING -> agg[0] += s.getDurationSeconds();
                case AUDIOBOOK -> agg[1] += s.getDurationSeconds();
                case TTS -> agg[2] += s.getDurationSeconds();
            }
            agg[3] += s.getPagesAdvanced();
        }

        List<DailyActivityResponse> dailyList = new ArrayList<>();
        LocalDate cur = startDate;
        while (!cur.isAfter(endDate)) {
            long[] agg = dateAggregates.get(cur);
            long readingMin = (agg != null) ? agg[0] / 60 : 0;
            long audioMin = (agg != null) ? agg[1] / 60 : 0;
            long ttsMin = (agg != null) ? agg[2] / 60 : 0;
            int pages = (agg != null) ? (int) agg[3] : 0;
            boolean active = (readingMin + audioMin + ttsMin) >= ReadingStreakService.MINIMUM_ACTIVE_MINUTES;

            dailyList.add(new DailyActivityResponse(cur, readingMin, audioMin, ttsMin, pages, active));
            cur = cur.plusDays(1);
        }

        return new ActivitySummaryResponse(periodUpper, year, dailyList);
    }

    public ReadingPaceResponse getReadingPace(UUID userId, Integer year, LocalDate from, LocalDate to) {
        LocalDate start = (from != null)
                ? from
                : (year != null ? LocalDate.of(year, 1, 1) : LocalDate.now().withDayOfYear(1));
        LocalDate end = (to != null)
                ? to
                : (year != null ? LocalDate.of(year, 12, 31) : LocalDate.now());

        OffsetDateTime startOffset = start.atStartOfDay().atOffset(ZoneOffset.UTC);
        OffsetDateTime endOffset = end.plusDays(1).atStartOfDay().atOffset(ZoneOffset.UTC).minusNanos(1);

        List<ReadingActivitySession> sessions =
                sessionRepository.findAllByUser_IdAndStartedAtBetweenOrderByStartedAtAsc(userId, startOffset, endOffset);

        Set<LocalDate> activeDays = new HashSet<>();
        long totalReadingSeconds = 0;
        long totalPages = 0;

        for (ReadingActivitySession s : sessions) {
            if (s.getActivityType() == ActivityType.READING) {
                totalReadingSeconds += s.getDurationSeconds();
                totalPages += s.getPagesAdvanced();
                activeDays.add(s.getStartedAt().toLocalDate());
            }
        }

        int activeDaysCount = activeDays.size();
        long totalReadingMinutes = totalReadingSeconds / 60;
        double pagesPerDay = activeDaysCount > 0 ? (double) totalPages / activeDaysCount : 0.0;
        double minutesPerDay = activeDaysCount > 0 ? (double) totalReadingMinutes / activeDaysCount : 0.0;

        return new ReadingPaceResponse(
                Math.round(pagesPerDay * 10.0) / 10.0,
                Math.round(minutesPerDay * 10.0) / 10.0,
                activeDaysCount,
                totalPages,
                totalReadingMinutes
        );
    }

    public BooksCompletedResponse getBooksCompleted(UUID userId, int year) {
        LocalDate startOfYear = LocalDate.of(year, 1, 1);
        LocalDate endOfYear = LocalDate.of(year, 12, 31);

        List<Book> completedBooks = bookRepository.findCompletedBooksBetween(userId, startOfYear, endOfYear);
        Map<Integer, Integer> monthCounts = new HashMap<>();
        for (Book b : completedBooks) {
            if (b.getCompletedAt() != null) {
                int m = b.getCompletedAt().getMonthValue();
                monthCounts.put(m, monthCounts.getOrDefault(m, 0) + 1);
            }
        }

        List<BooksCompletedResponse.MonthlyCompletedBooks> breakdown = new ArrayList<>();
        for (int m = 1; m <= 12; m++) {
            String name = Month.of(m).getDisplayName(TextStyle.SHORT, Locale.ENGLISH);
            breakdown.add(new BooksCompletedResponse.MonthlyCompletedBooks(
                    m, name, monthCounts.getOrDefault(m, 0)));
        }

        return new BooksCompletedResponse(year, completedBooks.size(), breakdown);
    }

    public GenreAnalyticsResponse getGenres(UUID userId, Integer year) {
        LocalDate start = (year != null) ? LocalDate.of(year, 1, 1) : null;
        LocalDate end = (year != null) ? LocalDate.of(year, 12, 31) : null;

        List<Object[]> rows = bookRepository.countCompletedBooksByGenre(userId, start, end);
        long totalCompleted = bookRepository.countCompletedBooksBetween(userId, start, end);

        List<GenreAnalyticsResponse.GenreData> genres = new ArrayList<>();
        for (Object[] row : rows) {
            String name = (String) row[0];
            long count = ((Number) row[1]).longValue();
            double pct = totalCompleted > 0 ? ((double) count / totalCompleted) * 100.0 : 0.0;
            genres.add(new GenreAnalyticsResponse.GenreData(name, count, Math.round(pct * 10.0) / 10.0));
        }

        return new GenreAnalyticsResponse(year, genres);
    }

    public AuthorAnalyticsResponse getAuthors(UUID userId, Integer year) {
        LocalDate start = (year != null) ? LocalDate.of(year, 1, 1) : null;
        LocalDate end = (year != null) ? LocalDate.of(year, 12, 31) : null;

        List<Object[]> rows = bookRepository.countCompletedBooksByAuthor(userId, start, end);
        long totalCompleted = bookRepository.countCompletedBooksBetween(userId, start, end);

        List<AuthorAnalyticsResponse.AuthorData> authors = new ArrayList<>();
        for (Object[] row : rows) {
            String name = (String) row[0];
            long count = ((Number) row[1]).longValue();
            double pct = totalCompleted > 0 ? ((double) count / totalCompleted) * 100.0 : 0.0;
            authors.add(new AuthorAnalyticsResponse.AuthorData(name, count, Math.round(pct * 10.0) / 10.0));
        }

        return new AuthorAnalyticsResponse(year, authors);
    }

    public ListeningAnalyticsResponse getListening(UUID userId, Integer year) {
        LocalDate start = (year != null) ? LocalDate.of(year, 1, 1) : LocalDate.of(1970, 1, 1);
        LocalDate end = (year != null) ? LocalDate.of(year, 12, 31) : LocalDate.of(2099, 12, 31);
        OffsetDateTime startOffset = start.atStartOfDay().atOffset(ZoneOffset.UTC);
        OffsetDateTime endOffset = end.plusDays(1).atStartOfDay().atOffset(ZoneOffset.UTC).minusNanos(1);

        List<Object[]> durationRows = sessionRepository.sumDurationByActivityType(userId, startOffset, endOffset);
        List<Object[]> sessionCounts = sessionRepository.countSessionsByActivityType(userId, startOffset, endOffset);

        long audiobookMins = 0;
        long ttsMins = 0;
        long audiobookSessions = 0;
        long ttsSessions = 0;

        for (Object[] row : durationRows) {
            ActivityType type = (ActivityType) row[0];
            long mins = ((Number) row[1]).longValue() / 60;
            if (type == ActivityType.AUDIOBOOK) audiobookMins = mins;
            if (type == ActivityType.TTS) ttsMins = mins;
        }

        for (Object[] row : sessionCounts) {
            ActivityType type = (ActivityType) row[0];
            long count = ((Number) row[1]).longValue();
            if (type == ActivityType.AUDIOBOOK) audiobookSessions = count;
            if (type == ActivityType.TTS) ttsSessions = count;
        }

        return new ListeningAnalyticsResponse(
                new ListeningAnalyticsResponse.ListeningCategoryData(audiobookMins, audiobookSessions),
                new ListeningAnalyticsResponse.ListeningCategoryData(ttsMins, ttsSessions),
                audiobookMins + ttsMins
        );
    }
}
