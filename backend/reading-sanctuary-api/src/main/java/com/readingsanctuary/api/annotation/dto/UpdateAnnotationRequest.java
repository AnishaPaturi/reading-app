package com.readingsanctuary.api.annotation.dto;

public record UpdateAnnotationRequest(
    String noteText,
    String color
) {}
