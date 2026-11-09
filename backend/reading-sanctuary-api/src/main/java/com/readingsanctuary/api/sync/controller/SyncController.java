package com.readingsanctuary.api.sync.controller;

import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.sync.dto.*;
import com.readingsanctuary.api.sync.service.SyncService;

@RestController
@RequestMapping("/api/v1/sync")
public class SyncController {

    private final SyncService syncService;

    public SyncController(SyncService syncService) {
        this.syncService = syncService;
    }

    @GetMapping("/pull")
    public ResponseEntity<SyncPullResponse> pull(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam("deviceId") UUID deviceId,
            @RequestParam(value = "cursor", defaultValue = "0") long cursor,
            @RequestParam(value = "limit", required = false) Integer limit) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(syncService.pull(userId, deviceId, cursor, limit));
    }

    @PostMapping("/push")
    public ResponseEntity<SyncPushResponse> push(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody SyncPushRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(syncService.push(userId, request));
    }

    @PostMapping("/acknowledge")
    public ResponseEntity<Void> acknowledge(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody SyncAcknowledgeRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        syncService.acknowledge(userId, request);
        return ResponseEntity.ok().build();
    }
}
