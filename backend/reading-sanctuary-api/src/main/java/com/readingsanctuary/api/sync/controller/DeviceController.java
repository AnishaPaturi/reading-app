package com.readingsanctuary.api.sync.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.sync.dto.DeviceRegistrationRequest;
import com.readingsanctuary.api.sync.dto.DeviceResponse;
import com.readingsanctuary.api.sync.service.DeviceService;

@RestController
@RequestMapping("/api/v1/sync/devices")
public class DeviceController {

    private final DeviceService deviceService;

    public DeviceController(DeviceService deviceService) {
        this.deviceService = deviceService;
    }

    @PostMapping
    public ResponseEntity<DeviceResponse> registerDevice(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody DeviceRegistrationRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.status(HttpStatus.CREATED).body(deviceService.registerDevice(userId, request));
    }

    @GetMapping
    public ResponseEntity<List<DeviceResponse>> listDevices(
            @AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(deviceService.listDevices(userId));
    }

    @DeleteMapping("/{deviceId}")
    public ResponseEntity<Void> deactivateDevice(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID deviceId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        deviceService.deactivateDevice(userId, deviceId);
        return ResponseEntity.noContent().build();
    }
}
