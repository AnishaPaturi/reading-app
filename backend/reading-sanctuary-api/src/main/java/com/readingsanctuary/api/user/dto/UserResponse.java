package com.readingsanctuary.api.user.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record UserResponse(
    UUID id,
    String email,
    boolean active,
    OffsetDateTime createdAt
) {}
