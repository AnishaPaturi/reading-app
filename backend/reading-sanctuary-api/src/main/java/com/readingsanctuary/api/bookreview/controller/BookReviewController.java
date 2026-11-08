package com.readingsanctuary.api.bookreview.controller;

import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.bookreview.dto.BookReviewRequest;
import com.readingsanctuary.api.bookreview.dto.BookReviewResponse;
import com.readingsanctuary.api.bookreview.service.BookReviewService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/review")
public class BookReviewController {

    private final BookReviewService reviewService;

    public BookReviewController(BookReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @PutMapping
    public ResponseEntity<BookReviewResponse> save(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @Valid @RequestBody BookReviewRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                reviewService.save(userId, bookId, request));
    }

    @GetMapping
    public ResponseEntity<BookReviewResponse> get(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                reviewService.get(userId, bookId));
    }

    @DeleteMapping
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        reviewService.delete(userId, bookId);

        return ResponseEntity.noContent().build();
    }
}
