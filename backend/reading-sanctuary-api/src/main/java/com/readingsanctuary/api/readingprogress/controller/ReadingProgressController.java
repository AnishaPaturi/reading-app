package com.readingsanctuary.api.readingprogress.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.readingprogress.dto.ReadingProgressRequest;
import com.readingsanctuary.api.readingprogress.dto.ReadingProgressResponse;
import com.readingsanctuary.api.readingprogress.service.ReadingProgressService;

@RestController
@RequestMapping("/api/v1/reading-progress")
public class ReadingProgressController {

    private final ReadingProgressService progressService;

    public ReadingProgressController(ReadingProgressService progressService) {
        this.progressService = progressService;
    }

    @GetMapping("/{bookFileId}")
    public ResponseEntity<ReadingProgressResponse> getProgress(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookFileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return progressService.getProgress(userId, bookFileId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping("/{bookFileId}")
    public ResponseEntity<ReadingProgressResponse> saveProgress(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookFileId,
            @Valid @RequestBody ReadingProgressRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(
                progressService.saveProgress(userId, bookFileId, request));
    }

    @GetMapping
    public ResponseEntity<List<ReadingProgressResponse>> getAllProgress(
            @AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(
                progressService.getAllProgress(userId));
    }

    @DeleteMapping("/{bookFileId}")
    public ResponseEntity<Void> resetProgress(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookFileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        progressService.resetProgress(userId, bookFileId);
        return ResponseEntity.noContent().build();
    }
}
