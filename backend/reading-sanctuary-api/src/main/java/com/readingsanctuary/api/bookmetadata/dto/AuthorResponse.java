package com.readingsanctuary.api.bookmetadata.dto;

import java.util.UUID;

public record AuthorResponse(
    UUID id,
    String name,
    String biography
) {}
