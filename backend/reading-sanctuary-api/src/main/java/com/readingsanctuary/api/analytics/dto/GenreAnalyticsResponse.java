package com.readingsanctuary.api.analytics.dto;

import java.util.List;

public record GenreAnalyticsResponse(
        Integer year,
        List<GenreData> genres
) {
    public record GenreData(
            String genre,
            long booksCompleted,
            double percentage
    ) {
    }
}
