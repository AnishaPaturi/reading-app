package com.readingsanctuary.api.bookmark.dto;

import java.util.UUID;

import com.readingsanctuary.api.common.enums.ReadingLocationType;

import jakarta.validation.constraints.*;

public record CreateBookmarkRequest(

    @NotNull
    UUID bookFileId,

    @Size(max = 150)
    String label,

    String note,

    @NotNull
    ReadingLocationType locationType,

    @NotBlank
    @Size(max = 2000)
    String locationValue,

    @Positive
    Integer pageNumber

) {}
