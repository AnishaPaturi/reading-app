package com.readingsanctuary.api.bookshelf.dto;

import java.util.UUID;

public record BookSizeCustomizationDto(
        UUID bookId,
        double heightFactor,
        String presetSize
) {}
