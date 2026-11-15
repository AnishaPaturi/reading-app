package com.readingsanctuary.api.annotation.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.annotation.dto.AnnotationResponse;
import com.readingsanctuary.api.annotation.dto.CreateAnnotationRequest;
import com.readingsanctuary.api.annotation.dto.UpdateAnnotationRequest;
import com.readingsanctuary.api.annotation.service.AnnotationService;

@RestController
@RequestMapping("/api/v1/annotations")
public class AnnotationController {

    private final AnnotationService annotationService;

    public AnnotationController(AnnotationService annotationService) {
        this.annotationService = annotationService;
    }

    @PostMapping
    public ResponseEntity<AnnotationResponse> createAnnotation(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateAnnotationRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        AnnotationResponse response = annotationService.createAnnotation(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/book-file/{bookFileId}")
    public ResponseEntity<List<AnnotationResponse>> getAnnotationsByBookFile(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookFileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        List<AnnotationResponse> list = annotationService.getAnnotationsByBookFile(userId, bookFileId);
        return ResponseEntity.ok(list);
    }

    @GetMapping("/book/{bookId}")
    public ResponseEntity<List<AnnotationResponse>> getAnnotationsByBook(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        List<AnnotationResponse> list = annotationService.getAnnotationsByBook(userId, bookId);
        return ResponseEntity.ok(list);
    }

    @PatchMapping("/{id}")
    public ResponseEntity<AnnotationResponse> updateAnnotation(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id,
            @RequestBody UpdateAnnotationRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        AnnotationResponse response = annotationService.updateAnnotation(userId, id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAnnotation(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id) {

        UUID userId = UUID.fromString(jwt.getSubject());
        annotationService.deleteAnnotation(userId, id);
        return ResponseEntity.noContent().build();
    }
}
