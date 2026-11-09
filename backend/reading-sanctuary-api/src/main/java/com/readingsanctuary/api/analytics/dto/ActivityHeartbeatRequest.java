package com.readingsanctuary.api.analytics.dto;

import jakarta.validation.constraints.Min;

public record ActivityHeartbeatRequest(
        Double progress,
        @Min(value = 0, message = "Pages advanced cannot be negative")
        Integer pagesAdvanced
) {
}
