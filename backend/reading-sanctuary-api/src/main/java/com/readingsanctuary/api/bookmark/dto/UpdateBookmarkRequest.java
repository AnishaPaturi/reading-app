package com.readingsanctuary.api.bookmark.dto;

import jakarta.validation.constraints.Size;

public record UpdateBookmarkRequest(

    @Size(max = 150)
    String label,

    String note

) {}
