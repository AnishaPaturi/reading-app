package com.readingsanctuary.api.readerposition.controller;

import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.readerposition.dto.ReadingPositionResponse;
import com.readingsanctuary.api.readerposition.dto.SaveReadingPositionRequest;
import com.readingsanctuary.api.readerposition.service.BookReadingPositionService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/files/{fileId}/reading-position")
public class BookReadingPositionController {

    private final BookReadingPositionService positionService;

    public BookReadingPositionController(BookReadingPositionService positionService) {
        this.positionService = positionService;
    }

    @GetMapping
    public ResponseEntity<ReadingPositionResponse> get(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return positionService.getPosition(userId, bookId, fileId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping
    public ResponseEntity<ReadingPositionResponse> saveOrUpdate(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId,
            @Valid @RequestBody SaveReadingPositionRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(positionService.saveOrUpdate(userId, bookId, fileId, request));
    }

    @DeleteMapping
    public ResponseEntity<Void> reset(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        positionService.resetPosition(userId, bookId, fileId);
        return ResponseEntity.noContent().build();
    }
}
