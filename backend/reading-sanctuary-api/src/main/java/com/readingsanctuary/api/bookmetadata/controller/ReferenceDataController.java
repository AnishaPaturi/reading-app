package com.readingsanctuary.api.bookmetadata.controller;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.bookmetadata.dto.*;
import com.readingsanctuary.api.bookmetadata.service.ReferenceDataService;

@RestController
@RequestMapping("/api/v1")
public class ReferenceDataController {

    private final ReferenceDataService referenceDataService;

    public ReferenceDataController(
            ReferenceDataService referenceDataService) {
        this.referenceDataService = referenceDataService;
    }

    @PostMapping("/authors")
    public ResponseEntity<AuthorResponse> createAuthor(
            @Valid @RequestBody CreateAuthorRequest request) {

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(referenceDataService.createAuthor(
                        request.name(), request.biography()));
    }

    @GetMapping("/authors")
    public ResponseEntity<List<AuthorResponse>> getAuthors() {

        return ResponseEntity.ok(referenceDataService.getAuthors());
    }

    @PostMapping("/genres")
    public ResponseEntity<GenreResponse> createGenre(
            @Valid @RequestBody CreateGenreRequest request) {

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(referenceDataService.createGenre(
                        request.name(), request.description()));
    }

    @GetMapping("/genres")
    public ResponseEntity<List<GenreResponse>> getGenres() {

        return ResponseEntity.ok(referenceDataService.getGenres());
    }
}
