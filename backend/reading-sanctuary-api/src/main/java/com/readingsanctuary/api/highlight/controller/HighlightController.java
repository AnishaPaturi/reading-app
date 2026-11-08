package com.readingsanctuary.api.highlight.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.highlight.dto.*;
import com.readingsanctuary.api.highlight.service.HighlightService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/highlights")
public class HighlightController {

    private final HighlightService highlightService;

    public HighlightController(HighlightService highlightService) {
        this.highlightService = highlightService;
    }

    @PostMapping
    public ResponseEntity<HighlightResponse> create(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @Valid @RequestBody CreateHighlightRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(highlightService.create(userId, bookId, request));
    }

    @GetMapping
    public List<HighlightResponse> getAll(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return highlightService.getAll(userId, bookId);
    }

    @PatchMapping("/{highlightId}")
    public HighlightResponse update(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID highlightId,
            @Valid @RequestBody UpdateHighlightRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return highlightService.update(
                userId, bookId, highlightId, request);
    }

    @DeleteMapping("/{highlightId}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID highlightId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        highlightService.delete(userId, bookId, highlightId);
        return ResponseEntity.noContent().build();
    }
}
