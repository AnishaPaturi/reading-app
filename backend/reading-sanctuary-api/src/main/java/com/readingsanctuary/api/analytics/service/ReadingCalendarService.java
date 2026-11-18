package com.readingsanctuary.api.analytics.service;

import java.time.LocalDate;
import java.time.YearMonth;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.*;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.analytics.dto.CalendarDayResponse;
import com.readingsanctuary.api.analytics.dto.CalendarDayResponse.CalendarBookActivity;
import com.readingsanctuary.api.analytics.dto.CalendarMonthResponse;
import com.readingsanctuary.api.analytics.entity.ReadingActivitySession;
import com.readingsanctuary.api.analytics.repository.ReadingActivitySessionRepository;
import com.readingsanctuary.api.book.entity.Book;

@Service
@Transactional(readOnly = true)
public class ReadingCalendarService {

    private final ReadingActivitySessionRepository sessionRepository;

    public ReadingCalendarService(ReadingActivitySessionRepository sessionRepository) {
        this.sessionRepository = sessionRepository;
    }

    public CalendarMonthResponse getMonthCalendar(UUID userId, Integer yearParam, Integer monthParam, ZoneId zoneId) {
        ZoneId zone = (zoneId != null) ? zoneId : ZoneOffset.UTC;
        LocalDate today = LocalDate.now(zone);

        int year = (yearParam != null) ? yearParam : today.getYear();
        int month = (monthParam != null) ? monthParam : today.getMonthValue();
        YearMonth yearMonth = YearMonth.of(year, month);
        int daysInMonth = yearMonth.lengthOfMonth();

        List<ReadingActivitySession> allSessions = sessionRepository.findAllByUser_IdOrderByStartedAtDesc(userId);

        // Group sessions by local date
        Map<LocalDate, List<ReadingActivitySession>> sessionsByDate = new HashMap<>();
        for (ReadingActivitySession s : allSessions) {
            LocalDate sessionDate = s.getStartedAt().atZoneSameInstant(zone).toLocalDate();
            if (sessionDate.getYear() == year && sessionDate.getMonthValue() == month) {
                sessionsByDate.computeIfAbsent(sessionDate, k -> new ArrayList<>()).add(s);
            }
        }

        List<CalendarDayResponse> daysList = new ArrayList<>(daysInMonth);
        int totalDaysRead = 0;
        int totalDaysMissed = 0;
        int totalPages = 0;
        int totalMinutes = 0;
        int bestStreakInMonth = 0;
        int currentRun = 0;

        for (int day = 1; day <= daysInMonth; day++) {
            LocalDate date = LocalDate.of(year, month, day);
            boolean isToday = date.equals(today);
            boolean isFuture = date.isAfter(today);

            List<ReadingActivitySession> daySessions = sessionsByDate.getOrDefault(date, Collections.emptyList());

            int dayPages = 0;
            int daySeconds = 0;
            Map<UUID, CalendarBookActivityAccumulator> booksMap = new LinkedHashMap<>();

            for (ReadingActivitySession s : daySessions) {
                dayPages += s.getPagesAdvanced();
                daySeconds += s.getDurationSeconds();

                Book book = s.getBook();
                if (book != null) {
                    CalendarBookActivityAccumulator acc = booksMap.computeIfAbsent(book.getId(), id ->
                            new CalendarBookActivityAccumulator(
                                    id.toString(),
                                    book.getTitle(),
                                    book.getPublisher() != null ? book.getPublisher() : "Author"
                            )
                    );
                    acc.pages += s.getPagesAdvanced();
                    acc.seconds += s.getDurationSeconds();
                }
            }

            int dayMinutes = daySeconds / 60;
            boolean hasRead = daySessions.size() > 0 && (dayPages > 0 || dayMinutes > 0);

            if (!isFuture) {
                if (hasRead) {
                    totalDaysRead++;
                    currentRun++;
                    if (currentRun > bestStreakInMonth) {
                        bestStreakInMonth = currentRun;
                    }
                } else {
                    currentRun = 0;
                    if (!isToday) {
                        totalDaysMissed++;
                    }
                }
            }

            totalPages += dayPages;
            totalMinutes += dayMinutes;

            List<CalendarBookActivity> bookActivities = booksMap.values().stream()
                    .map(acc -> new CalendarBookActivity(acc.bookId, acc.title, acc.author, acc.pages, acc.seconds / 60))
                    .toList();

            daysList.add(new CalendarDayResponse(
                    date,
                    hasRead,
                    isToday,
                    isFuture,
                    dayPages,
                    dayMinutes,
                    booksMap.size(),
                    bookActivities
            ));
        }

        String monthStr = String.format("%04d-%02d", year, month);

        return new CalendarMonthResponse(
                monthStr,
                year,
                month,
                totalDaysRead,
                totalDaysMissed,
                totalPages,
                totalMinutes,
                bestStreakInMonth,
                daysList
        );
    }

    private static class CalendarBookActivityAccumulator {
        final String bookId;
        final String title;
        final String author;
        int pages = 0;
        int seconds = 0;

        CalendarBookActivityAccumulator(String bookId, String title, String author) {
            this.bookId = bookId;
            this.title = title;
            this.author = author;
        }
    }
}
