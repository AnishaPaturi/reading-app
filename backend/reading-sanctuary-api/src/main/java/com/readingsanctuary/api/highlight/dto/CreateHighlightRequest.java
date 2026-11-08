package com.readingsanctuary.api.highlight.dto;

import java.util.UUID;

import com.readingsanctuary.api.common.enums.HighlightColor;
import com.readingsanctuary.api.common.enums.ReadingLocationType;

import jakarta.validation.constraints.*;

public record CreateHighlightRequest(

    @NotNull
    UUID bookFileId,

    @NotBlank
    String selectedText,

    @NotNull
    ReadingLocationType locationType,

    @NotBlank
    @Size(max = 2000)
    String startLocation,

    @NotBlank
    @Size(max = 2000)
    String endLocation,

    @Positive
    Integer pageNumber,

    HighlightColor color,

    String annotationNote

) {}
