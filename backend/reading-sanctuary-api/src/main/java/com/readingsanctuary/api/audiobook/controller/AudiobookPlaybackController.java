package com.readingsanctuary.api.audiobook.controller;

import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.audiobook.dto.AudioPositionResponse;
import com.readingsanctuary.api.audiobook.dto.SaveAudioPositionRequest;
import com.readingsanctuary.api.audiobook.service.AudiobookPlaybackService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/files/{fileId}/audio-position")
public class AudiobookPlaybackController {

    private final AudiobookPlaybackService playbackService;

    public AudiobookPlaybackController(AudiobookPlaybackService playbackService) {
        this.playbackService = playbackService;
    }

    @GetMapping
    public ResponseEntity<AudioPositionResponse> get(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return playbackService.getPosition(userId, bookId, fileId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping
    public ResponseEntity<AudioPositionResponse> saveOrUpdate(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId,
            @Valid @RequestBody SaveAudioPositionRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(playbackService.saveOrUpdate(userId, bookId, fileId, request));
    }

    @DeleteMapping
    public ResponseEntity<Void> reset(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        playbackService.resetPosition(userId, bookId, fileId);
        return ResponseEntity.noContent().build();
    }
}
