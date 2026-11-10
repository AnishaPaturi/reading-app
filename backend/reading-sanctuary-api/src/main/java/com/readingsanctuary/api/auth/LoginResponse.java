package com.readingsanctuary.api.auth;

import java.util.UUID;

public record LoginResponse(
    String accessToken,
    String tokenType,
    long expiresIn,
    UUID userId,
    String email,
    String displayName,
    String profilePictureUrl
) {}
