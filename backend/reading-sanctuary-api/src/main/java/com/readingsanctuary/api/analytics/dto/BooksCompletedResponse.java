package com.readingsanctuary.api.analytics.dto;

import java.util.List;

public record BooksCompletedResponse(
        int year,
        int totalCompleted,
        List<MonthlyCompletedBooks> monthlyBreakdown
) {
    public record MonthlyCompletedBooks(
            int month,
            String monthName,
            int count
    ) {
    }
}
