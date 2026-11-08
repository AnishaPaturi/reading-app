package com.readingsanctuary.api.note.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateBookNoteRequest(

    @NotBlank
    @Size(max = 200)
    String title,

    @NotBlank
    String content

) {}
