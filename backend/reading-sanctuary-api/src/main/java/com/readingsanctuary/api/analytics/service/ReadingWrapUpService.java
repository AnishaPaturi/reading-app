package com.readingsanctuary.api.analytics.service;

import java.time.LocalDate;
import java.time.Month;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.TextStyle;
import java.util.*;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.analytics.dto.StreakResponse;
import com.readingsanctuary.api.analytics.dto.YearlyWrapUpResponse;
import com.readingsanctuary.api.analytics.entity.ReadingActivitySession;
import com.readingsanctuary.api.analytics.enums.ActivityType;
import com.readingsanctuary.api.analytics.repository.ReadingActivitySessionRepository;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;

@Service
@Transactional(readOnly = true)
public class ReadingWrapUpService {

    private final BookRepository bookRepository;
    private final ReadingActivitySessionRepository sessionRepository;
    private final ReadingStreakService streakService;

    public ReadingWrapUpService(
            BookRepository bookRepository,
            ReadingActivitySessionRepository sessionRepository,
            ReadingStreakService streakService) {
        this.bookRepository = bookRepository;
        this.sessionRepository = sessionRepository;
        this.streakService = streakService;
    }

    public YearlyWrapUpResponse generateWrapUp(UUID userId, int year) {
        LocalDate startOfYear = LocalDate.of(year, 1, 1);
        LocalDate endOfYear = LocalDate.of(year, 12, 31);
        OffsetDateTime startOffset = startOfYear.atStartOfDay().atOffset(ZoneOffset.UTC);
        OffsetDateTime endOffset = endOfYear.plusDays(1).atStartOfDay().atOffset(ZoneOffset.UTC).minusNanos(1);

        long totalCompleted = bookRepository.countCompletedBooksBetween(userId, startOfYear, endOfYear);

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

        List<Object[]> genreRows = bookRepository.countCompletedBooksByGenre(userId, startOfYear, endOfYear);
        String mostReadGenre = genreRows.isEmpty() ? "None" : (String) genreRows.get(0)[0];

        List<Object[]> authorRows = bookRepository.countCompletedBooksByAuthor(userId, startOfYear, endOfYear);
        String mostReadAuthor = authorRows.isEmpty() ? "None" : (String) authorRows.get(0)[0];

        StreakResponse streakInfo = streakService.calculateStreaks(userId, ZoneOffset.UTC);
        int longestStreak = streakInfo.longestStreak();

        // Calculate most active month (by completed books or activity minutes)
        List<Book> completedBooks = bookRepository.findCompletedBooksBetween(userId, startOfYear, endOfYear);
        Map<Integer, Integer> monthCounts = new HashMap<>();
        for (Book b : completedBooks) {
            if (b.getCompletedAt() != null) {
                int m = b.getCompletedAt().getMonthValue();
                monthCounts.put(m, monthCounts.getOrDefault(m, 0) + 1);
            }
        }

        int maxMonth = 1;
        int maxCount = -1;
        for (int m = 1; m <= 12; m++) {
            int cnt = monthCounts.getOrDefault(m, 0);
            if (cnt > maxCount) {
                maxCount = cnt;
                maxMonth = m;
            }
        }

        String mostActiveMonth = (maxCount > 0)
                ? Month.of(maxMonth).getDisplayName(TextStyle.FULL, Locale.ENGLISH)
                : "None";

        double avgBooksPerMonth = Math.round((totalCompleted / 12.0) * 10.0) / 10.0;

        return new YearlyWrapUpResponse(
                year,
                totalCompleted,
                readingMinutes,
                audiobookMinutes,
                ttsMinutes,
                pagesAdvanced,
                mostReadGenre,
                mostReadAuthor,
                longestStreak,
                mostActiveMonth,
                avgBooksPerMonth
        );
    }
}
