package com.readingsanctuary.api.tts.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.*;

public record SaveTtsPositionRequest(

    @NotNull
    @PositiveOrZero
    Integer chapterIndex,

    @NotNull
    @PositiveOrZero
    Integer chunkIndex,

    @NotNull
    @PositiveOrZero
    Integer characterOffset,

    @NotNull
    @DecimalMin(value = "0.00")
    @DecimalMax(value = "100.00")
    BigDecimal progressPercentage

) {}
