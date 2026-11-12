package com.readingsanctuary.api.auth;

import com.fasterxml.jackson.annotation.JsonAlias;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LoginRequest(

    @NotBlank(message = "Email or username is required")
    @Size(max = 255, message = "Identifier cannot exceed 255 characters")
    @JsonAlias({"username", "identifier", "login"})
    String email,

    @NotBlank(message = "Password is required")
    String password

) {}
