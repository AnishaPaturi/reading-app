package com.readingsanctuary.api.analytics.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.analytics.dto.GoalProgressResponse;
import com.readingsanctuary.api.analytics.dto.ReadingGoalRequest;
import com.readingsanctuary.api.analytics.dto.ReadingGoalResponse;
import com.readingsanctuary.api.analytics.service.ReadingGoalService;

@RestController
@RequestMapping({"/api/v1/goals", "/api/v1/analytics/goals"})
public class ReadingGoalController {

    private final ReadingGoalService goalService;

    public ReadingGoalController(ReadingGoalService goalService) {
        this.goalService = goalService;
    }

    @PostMapping
    public ResponseEntity<ReadingGoalResponse> createGoal(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody ReadingGoalRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.status(HttpStatus.CREATED).body(goalService.createGoal(userId, request));
    }

    @GetMapping
    public ResponseEntity<List<ReadingGoalResponse>> getGoals(
            @AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(goalService.getGoals(userId));
    }

    @GetMapping("/{goalId}")
    public ResponseEntity<ReadingGoalResponse> getGoal(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID goalId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(goalService.getGoal(userId, goalId));
    }

    @PutMapping("/{goalId}")
    public ResponseEntity<ReadingGoalResponse> updateGoal(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID goalId,
            @Valid @RequestBody ReadingGoalRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(goalService.updateGoal(userId, goalId, request));
    }

    @DeleteMapping("/{goalId}")
    public ResponseEntity<Void> deleteGoal(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID goalId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        goalService.deleteGoal(userId, goalId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{goalId}/progress")
    public ResponseEntity<GoalProgressResponse> getGoalProgress(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID goalId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(goalService.calculateProgress(userId, goalId));
    }
}
