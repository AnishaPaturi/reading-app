package com.readingsanctuary.api.user.controller;

import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.user.dto.UserRegistrationRequest;
import com.readingsanctuary.api.user.dto.UserResponse;
import com.readingsanctuary.api.user.service.UserService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/users")
@Validated
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/register")
    public ResponseEntity<UserResponse> registerUser(
            @Valid @RequestBody UserRegistrationRequest request) {

        UserResponse response = userService.registerUser(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @GetMapping("/me")
    public ResponseEntity<UserResponse> getCurrentUser(@AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        UserResponse response = userService.getUserById(userId);
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/me")
    public ResponseEntity<UserResponse> updateProfile(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody Map<String, String> body) {
        UUID userId = UUID.fromString(jwt.getSubject());
        String displayName = body.get("displayName");
        UserResponse response = userService.updateProfile(userId, displayName);
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/me/gender")
    public ResponseEntity<UserResponse> setGender(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody Map<String, String> body) {
        UUID userId = UUID.fromString(jwt.getSubject());
        String gender = body.get("gender");
        if (gender == null || gender.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Gender is required");
        }
        UserResponse response = userService.updateGender(userId, gender);
        return ResponseEntity.ok(response);
    }
}
