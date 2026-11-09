package com.readingsanctuary.api.analytics.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.analytics.dto.ActivityHeartbeatRequest;
import com.readingsanctuary.api.analytics.dto.ActivitySessionRequest;
import com.readingsanctuary.api.analytics.dto.ActivitySessionResponse;
import com.readingsanctuary.api.analytics.dto.CloseSessionRequest;
import com.readingsanctuary.api.analytics.service.ActivitySessionService;

@RestController
@RequestMapping({"/api/v1/activity-sessions", "/api/v1/analytics/sessions"})
public class ActivitySessionController {

    private final ActivitySessionService sessionService;

    public ActivitySessionController(ActivitySessionService sessionService) {
        this.sessionService = sessionService;
    }

    @PostMapping({"", "/start"})
    public ResponseEntity<ActivitySessionResponse> startSession(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody ActivitySessionRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.status(HttpStatus.CREATED).body(sessionService.startSession(userId, request));
    }

    @RequestMapping(value = "/{sessionId}/heartbeat", method = {RequestMethod.POST, RequestMethod.PATCH})
    public ResponseEntity<ActivitySessionResponse> heartbeat(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID sessionId,
            @Valid @RequestBody ActivityHeartbeatRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(sessionService.heartbeat(userId, sessionId, request));
    }

    @PostMapping("/{sessionId}/close")
    public ResponseEntity<ActivitySessionResponse> closeSession(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID sessionId,
            @RequestBody(required = false) CloseSessionRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(sessionService.closeSession(userId, sessionId, request));
    }

    @GetMapping
    public ResponseEntity<List<ActivitySessionResponse>> getSessionHistory(
            @AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(sessionService.getSessionHistory(userId));
    }
}
