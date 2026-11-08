package com.readingsanctuary.api.bookshelf.dto;

import jakarta.validation.constraints.Size;

public record UpdateBookshelfRequest(

    @Size(max = 100)
    String name,

    String description,

    @Size(max = 20)
    String color

) {}
