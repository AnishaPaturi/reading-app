package com.readingsanctuary.api.note.controller;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.note.dto.*;
import com.readingsanctuary.api.note.service.BookNoteService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/notes")
public class BookNoteController {

    private final BookNoteService noteService;

    public BookNoteController(BookNoteService noteService) {
        this.noteService = noteService;
    }

    @PostMapping
    public ResponseEntity<BookNoteResponse> create(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @Valid @RequestBody CreateBookNoteRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(noteService.create(userId, bookId, request));
    }

    @GetMapping
    public List<BookNoteResponse> getAll(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return noteService.getAll(userId, bookId);
    }

    @GetMapping("/{noteId}")
    public BookNoteResponse getOne(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID noteId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return noteService.getOne(userId, bookId, noteId);
    }

    @PatchMapping("/{noteId}")
    public BookNoteResponse update(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID noteId,
            @Valid @RequestBody UpdateBookNoteRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return noteService.update(
                userId, bookId, noteId, request);
    }

    @DeleteMapping("/{noteId}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID noteId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        noteService.delete(userId, bookId, noteId);
        return ResponseEntity.noContent().build();
    }
}
