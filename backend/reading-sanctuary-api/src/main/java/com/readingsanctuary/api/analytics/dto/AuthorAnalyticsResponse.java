package com.readingsanctuary.api.analytics.dto;

import java.util.List;

public record AuthorAnalyticsResponse(
        Integer year,
        List<AuthorData> authors
) {
    public record AuthorData(
            String author,
            long booksCompleted,
            double percentage
    ) {
    }
}
