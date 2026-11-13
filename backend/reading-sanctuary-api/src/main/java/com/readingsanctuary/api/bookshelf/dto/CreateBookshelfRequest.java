package com.readingsanctuary.api.bookshelf.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateBookshelfRequest(

    @NotBlank
    @Size(max = 100)
    String name,

    String description,

    @Size(max = 20)
    String color,

    @Size(max = 30)
    String themeColor,

    @Size(max = 30)
    String accentColor,

    @Size(max = 100)
    String icon,

    @Size(max = 50)
    String backgroundStyle,

    @Size(max = 50)
    String layoutStyle,

    Boolean isFavorite,

    Integer sortOrder

) {}
