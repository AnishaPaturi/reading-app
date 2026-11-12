package com.readingsanctuary.api.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record GoogleLoginRequest(
    @NotBlank(message = "Google ID token is required")
    @Size(max = 8192, message = "Google ID token is too large")
    String idToken
) {}
