package com.readingsanctuary.api.audiobook.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.audiobook.dto.AudiobookResponseDto;
import com.readingsanctuary.api.audiobook.dto.AudiobookSyncDto;
import com.readingsanctuary.api.audiobook.service.AudiobookSyncService;

@RestController
@RequestMapping("/api/v1/audiobooks")
public class AudiobookController {

    private final AudiobookSyncService syncService;

    public AudiobookController(AudiobookSyncService syncService) {
        this.syncService = syncService;
    }

    @PostMapping("/sync")
    public ResponseEntity<AudiobookResponseDto> sync(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AudiobookSyncDto request) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(syncService.syncAudiobook(userId, request));
    }

    @GetMapping
    public ResponseEntity<List<AudiobookResponseDto>> getLibrary(
            @AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(syncService.getUserAudiobooks(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<AudiobookResponseDto> getAudiobook(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return syncService.getAudiobook(userId, id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAudiobook(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id) {
        UUID userId = UUID.fromString(jwt.getSubject());
        syncService.deleteAudiobook(userId, id);
        return ResponseEntity.noContent().build();
    }
}
