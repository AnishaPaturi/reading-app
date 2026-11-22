package com.readingsanctuary.api.analytics.dto;

import java.time.LocalDate;
import java.util.List;

public record CalendarDayResponse(
        LocalDate date,
        boolean hasRead,
        boolean isToday,
        boolean isFuture,
        int pagesRead,
        int minutesRead,
        int booksReadCount,
        List<CalendarBookActivity> books
) {
    public record CalendarBookActivity(
            String bookId,
            String title,
            String author,
            int pagesRead,
            int minutesRead
    ) {}
}
