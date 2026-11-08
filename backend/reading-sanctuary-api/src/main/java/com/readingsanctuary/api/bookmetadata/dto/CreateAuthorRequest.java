package com.readingsanctuary.api.bookmetadata.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateAuthorRequest(
    @NotBlank
    @Size(max = 255)
    String name,

    String biography
) {}
