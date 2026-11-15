package com.readingsanctuary.api.annotation.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record CreateAnnotationRequest(
    UUID bookId,

    @NotNull(message = "bookFileId is required")
    UUID bookFileId,

    @NotBlank(message = "type is required")
    @Pattern(regexp = "(?i)^(HIGHLIGHT|NOTE)$", message = "type must be either HIGHLIGHT or NOTE")
    String type,

    String selectedText,

    String noteText,

    String color,

    Integer pageNumber,

    String locationData
) {}
