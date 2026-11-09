package com.readingsanctuary.api.audiobook.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.*;

public record SaveAudioPositionRequest(

    @NotNull
    @PositiveOrZero
    Long positionMs,

    @NotNull
    @PositiveOrZero
    Long durationMs,

    @NotNull
    @DecimalMin(value = "0.50")
    @DecimalMax(value = "3.00")
    BigDecimal playbackSpeed,

    @NotNull
    Boolean isCompleted

) {}
