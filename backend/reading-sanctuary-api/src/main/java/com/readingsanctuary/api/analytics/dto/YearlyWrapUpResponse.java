package com.readingsanctuary.api.analytics.dto;

public record YearlyWrapUpResponse(
        int year,
        long totalCompletedBooks,
        long totalReadingMinutes,
        long totalAudiobookMinutes,
        long totalTtsMinutes,
        long totalPagesAdvanced,
        String mostReadGenre,
        String mostReadAuthor,
        int longestStreak,
        String mostActiveMonth,
        double averageBooksPerMonth
) {
}
