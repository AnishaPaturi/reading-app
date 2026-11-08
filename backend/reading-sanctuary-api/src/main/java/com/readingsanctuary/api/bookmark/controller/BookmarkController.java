package com.readingsanctuary.api.bookmark.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.bookmark.dto.*;
import com.readingsanctuary.api.bookmark.service.BookmarkService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/bookmarks")
public class BookmarkController {

    private final BookmarkService bookmarkService;

    public BookmarkController(BookmarkService bookmarkService) {
        this.bookmarkService = bookmarkService;
    }

    @PostMapping
    public ResponseEntity<BookmarkResponse> create(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @Valid @RequestBody CreateBookmarkRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(bookmarkService.create(userId, bookId, request));
    }

    @GetMapping
    public List<BookmarkResponse> getAll(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return bookmarkService.getAll(userId, bookId);
    }

    @PatchMapping("/{bookmarkId}")
    public BookmarkResponse update(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID bookmarkId,
            @Valid @RequestBody UpdateBookmarkRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return bookmarkService.update(
                userId, bookId, bookmarkId, request);
    }

    @DeleteMapping("/{bookmarkId}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID bookmarkId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        bookmarkService.delete(userId, bookId, bookmarkId);
        return ResponseEntity.noContent().build();
    }
}
