package com.readingsanctuary.api.bookmetadata.dto;

import java.util.UUID;

public record GenreResponse(
    UUID id,
    String name,
    String description
) {}
