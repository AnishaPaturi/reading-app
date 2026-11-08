package com.readingsanctuary.api.collection.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateCollectionRequest(

    @NotBlank
    @Size(max = 100)
    String name,

    String description,

    UUID parentId

) {}
