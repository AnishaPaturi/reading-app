package com.readingsanctuary.api.bookmetadata.controller;

import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.bookmetadata.dto.BookMetadataRequest;
import com.readingsanctuary.api.bookmetadata.dto.BookMetadataResponse;
import com.readingsanctuary.api.bookmetadata.service.BookMetadataService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/metadata")
public class BookMetadataController {

    private final BookMetadataService metadataService;

    public BookMetadataController(BookMetadataService metadataService) {
        this.metadataService = metadataService;
    }

    @GetMapping
    public ResponseEntity<BookMetadataResponse> getMetadata(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                metadataService.getMetadata(userId, bookId));
    }

    @PatchMapping
    public ResponseEntity<BookMetadataResponse> updateMetadata(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @Valid @RequestBody BookMetadataRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                metadataService.updateMetadata(userId, bookId, request));
    }
}
