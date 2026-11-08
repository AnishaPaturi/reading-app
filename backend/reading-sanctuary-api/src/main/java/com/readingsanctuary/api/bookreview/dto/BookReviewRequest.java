package com.readingsanctuary.api.bookreview.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

public record BookReviewRequest(
    @Min(1)
    @Max(5)
    Integer rating,

    String review
) {}
