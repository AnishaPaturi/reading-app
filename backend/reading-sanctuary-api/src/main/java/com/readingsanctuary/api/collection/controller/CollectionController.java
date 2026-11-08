package com.readingsanctuary.api.collection.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.collection.dto.CollectionResponse;
import com.readingsanctuary.api.collection.dto.CreateCollectionRequest;
import com.readingsanctuary.api.collection.dto.UpdateCollectionRequest;
import com.readingsanctuary.api.collection.service.CollectionService;

@RestController
@RequestMapping({"/api/v1/collections", "/api/collections"})
public class CollectionController {

    private final CollectionService collectionService;

    public CollectionController(CollectionService collectionService) {
        this.collectionService = collectionService;
    }

    @PostMapping
    public ResponseEntity<CollectionResponse> create(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateCollectionRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(collectionService.create(userId, request));
    }

    @GetMapping
    public ResponseEntity<List<CollectionResponse>> getAll(
            @AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(collectionService.getAll(userId));
    }

    @PatchMapping("/{collectionId}")
    public ResponseEntity<CollectionResponse> update(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID collectionId,
            @Valid @RequestBody UpdateCollectionRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                collectionService.update(userId, collectionId, request));
    }

    @DeleteMapping("/{collectionId}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID collectionId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        collectionService.delete(userId, collectionId);

        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{collectionId}/books/{bookId}")
    public ResponseEntity<Void> addBook(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID collectionId,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        collectionService.addBook(userId, collectionId, bookId);

        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{collectionId}/books/{bookId}")
    public ResponseEntity<Void> removeBook(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID collectionId,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        collectionService.removeBook(userId, collectionId, bookId);

        return ResponseEntity.noContent().build();
    }
}
