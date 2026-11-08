package com.readingsanctuary.api.bookshelf.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateBookshelfRequest(

    @NotBlank
    @Size(max = 100)
    String name,

    String description,

    @Size(max = 20)
    String color

) {}
