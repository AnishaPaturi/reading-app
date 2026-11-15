package com.readingsanctuary.api.audiobook.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.audiobook.dto.AudiobookBookmarkDto;
import com.readingsanctuary.api.audiobook.service.AudiobookBookmarkSyncService;

@RestController
@RequestMapping("/api/v1/audiobooks")
public class AudiobookBookmarkController {

    private final AudiobookBookmarkSyncService bookmarkService;

    public AudiobookBookmarkController(AudiobookBookmarkSyncService bookmarkService) {
        this.bookmarkService = bookmarkService;
    }

    @PostMapping("/{id}/bookmarks")
    public ResponseEntity<AudiobookBookmarkDto> addBookmark(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id,
            @Valid @RequestBody AudiobookBookmarkDto request) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(bookmarkService.addBookmark(userId, id, request));
    }

    @GetMapping("/{id}/bookmarks")
    public ResponseEntity<List<AudiobookBookmarkDto>> getBookmarks(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(bookmarkService.getBookmarksForBook(userId, id));
    }

    @GetMapping("/bookmarks")
    public ResponseEntity<List<AudiobookBookmarkDto>> getAllBookmarks(
            @AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(bookmarkService.getAllUserBookmarks(userId));
    }

    @PutMapping("/bookmarks/{bookmarkId}")
    public ResponseEntity<AudiobookBookmarkDto> updateBookmark(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookmarkId,
            @Valid @RequestBody AudiobookBookmarkDto request) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return bookmarkService.updateBookmark(userId, bookmarkId, request)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/bookmarks/{bookmarkId}")
    public ResponseEntity<Void> deleteBookmark(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookmarkId) {
        UUID userId = UUID.fromString(jwt.getSubject());
        bookmarkService.deleteBookmark(userId, bookmarkId);
        return ResponseEntity.noContent().build();
    }
}
