package com.readingsanctuary.api.collection.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record CollectionResponse(

    UUID id,

    String name,

    String description,

    UUID parentId,

    int bookCount,

    List<UUID> bookIds,

    OffsetDateTime createdAt

) {}
