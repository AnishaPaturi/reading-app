package com.readingsanctuary.api.audiobook.controller;

import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.audiobook.dto.AudiobookProgressDto;
import com.readingsanctuary.api.audiobook.service.AudiobookProgressSyncService;

@RestController
@RequestMapping("/api/v1/audiobooks/{id}/progress")
public class AudiobookProgressController {

    private final AudiobookProgressSyncService progressService;

    public AudiobookProgressController(AudiobookProgressSyncService progressService) {
        this.progressService = progressService;
    }

    @PutMapping
    public ResponseEntity<AudiobookProgressDto> updateProgress(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id,
            @Valid @RequestBody AudiobookProgressDto request) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(progressService.updateProgress(userId, id, request));
    }

    @GetMapping
    public ResponseEntity<AudiobookProgressDto> getProgress(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return progressService.getProgress(userId, id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
