package com.readingsanctuary.api.highlight.dto;

import com.readingsanctuary.api.common.enums.HighlightColor;

public record UpdateHighlightRequest(
    HighlightColor color,
    String annotationNote
) {}
