package com.readingsanctuary.api.audiobook.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.audiobook.dto.ListeningSessionDto;
import com.readingsanctuary.api.audiobook.service.AudiobookHistorySyncService;

@RestController
@RequestMapping("/api/v1/audiobooks")
public class AudiobookHistoryController {

    private final AudiobookHistorySyncService historyService;

    public AudiobookHistoryController(AudiobookHistorySyncService historyService) {
        this.historyService = historyService;
    }

    @PostMapping("/{id}/sessions")
    public ResponseEntity<ListeningSessionDto> saveSession(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id,
            @Valid @RequestBody ListeningSessionDto request) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(historyService.saveListeningSession(userId, id, request));
    }

    @GetMapping("/history")
    public ResponseEntity<List<ListeningSessionDto>> getHistory(
            @AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(historyService.getUserHistory(userId));
    }
}
