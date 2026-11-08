package com.readingsanctuary.api.readerposition.dto;

import java.math.BigDecimal;

import com.readingsanctuary.api.common.enums.ReadingLocationType;

import jakarta.validation.constraints.*;

public record SaveReadingPositionRequest(

    @NotNull
    ReadingLocationType locationType,

    @NotBlank
    @Size(max = 2000)
    String locationValue,

    @Positive
    Integer pageNumber,

    @Positive
    Integer totalPages,

    @NotNull
    @DecimalMin(value = "0.00")
    @DecimalMax(value = "100.00")
    BigDecimal progressPercentage

) {}
