package com.readingsanctuary.api.collection.dto;

import java.util.UUID;

import jakarta.validation.constraints.Size;

public record UpdateCollectionRequest(

    @Size(max = 100)
    String name,

    String description,

    UUID parentId

) {}
