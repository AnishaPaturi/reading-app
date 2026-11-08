package com.readingsanctuary.api.bookreading.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.bookreading.dto.*;
import com.readingsanctuary.api.bookreading.service.BookReadingService;

@RestController
@RequestMapping("/api/v1")
public class BookReadingController {

    private final BookReadingService readingService;

    public BookReadingController(BookReadingService readingService) {
        this.readingService = readingService;
    }

    @PatchMapping("/books/{bookId}/reading")
    public ResponseEntity<ReadingResponse> updateReading(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @Valid @RequestBody UpdateReadingRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                readingService.updateReading(userId, bookId, request));
    }

    @GetMapping("/books/{bookId}/reading")
    public ResponseEntity<ReadingResponse> getReading(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                readingService.getReading(userId, bookId));
    }

    @GetMapping("/books/reading")
    public ResponseEntity<List<ReadingResponse>> getBooksByStatus(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam ReadingStatus status) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                readingService.getBooksByStatus(userId, status));
    }

    @GetMapping("/books/{bookId}/history")
    public ResponseEntity<List<ReadingHistoryResponse>> getHistory(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                readingService.getHistory(userId, bookId));
    }
}
