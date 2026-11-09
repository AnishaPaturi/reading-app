package com.readingsanctuary.api.tts.controller;

import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.tts.dto.SaveTtsPositionRequest;
import com.readingsanctuary.api.tts.dto.TtsPositionResponse;
import com.readingsanctuary.api.tts.service.TtsPlaybackService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/files/{fileId}/tts-position")
public class TtsPlaybackController {

    private final TtsPlaybackService ttsService;

    public TtsPlaybackController(TtsPlaybackService ttsService) {
        this.ttsService = ttsService;
    }

    @GetMapping
    public ResponseEntity<TtsPositionResponse> get(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ttsService.getPosition(userId, bookId, fileId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping
    public ResponseEntity<TtsPositionResponse> saveOrUpdate(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId,
            @Valid @RequestBody SaveTtsPositionRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(ttsService.saveOrUpdate(userId, bookId, fileId, request));
    }

    @DeleteMapping
    public ResponseEntity<Void> reset(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        ttsService.resetPosition(userId, bookId, fileId);
        return ResponseEntity.noContent().build();
    }
}
