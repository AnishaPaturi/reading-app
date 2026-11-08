package com.readingsanctuary.api.bookshelf.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.bookshelf.dto.BookshelfResponse;
import com.readingsanctuary.api.bookshelf.dto.CreateBookshelfRequest;
import com.readingsanctuary.api.bookshelf.dto.UpdateBookshelfRequest;
import com.readingsanctuary.api.bookshelf.service.BookshelfService;

@RestController
@RequestMapping("/api/v1/shelves")
public class BookshelfController {

    private final BookshelfService shelfService;

    public BookshelfController(BookshelfService shelfService) {
        this.shelfService = shelfService;
    }

    @PostMapping
    public ResponseEntity<BookshelfResponse> create(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateBookshelfRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(shelfService.create(userId, request));
    }

    @GetMapping
    public ResponseEntity<List<BookshelfResponse>> getAll(
            @AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(shelfService.getAll(userId));
    }

    @PatchMapping("/{shelfId}")
    public ResponseEntity<BookshelfResponse> update(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID shelfId,
            @Valid @RequestBody UpdateBookshelfRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                shelfService.update(userId, shelfId, request));
    }

    @DeleteMapping("/{shelfId}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID shelfId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        shelfService.delete(userId, shelfId);

        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{shelfId}/books/{bookId}")
    public ResponseEntity<Void> addBook(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID shelfId,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        shelfService.addBook(userId, shelfId, bookId);

        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{shelfId}/books/{bookId}")
    public ResponseEntity<Void> removeBook(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID shelfId,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        shelfService.removeBook(userId, shelfId, bookId);

        return ResponseEntity.noContent().build();
    }
}
