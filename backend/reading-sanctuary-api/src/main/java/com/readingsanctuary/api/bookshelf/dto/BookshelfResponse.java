package com.readingsanctuary.api.bookshelf.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record BookshelfResponse(

    UUID id,

    String name,

    String description,

    String color,

    String themeColor,

    String accentColor,

    String icon,

    String backgroundStyle,

    String layoutStyle,

    boolean isFavorite,

    int sortOrder,

    int bookCount,

    List<UUID> bookIds,

    OffsetDateTime createdAt

) {}
