package com.readingsanctuary.api.bookmetadata.cover.controller;

import java.util.UUID;

import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.readingsanctuary.api.bookmetadata.cover.service.BookCoverService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/cover")
public class BookCoverController {

    private final BookCoverService coverService;

    public BookCoverController(BookCoverService coverService) {
        this.coverService = coverService;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Void> uploadCover(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @RequestParam("file") MultipartFile file) {

        UUID userId = UUID.fromString(jwt.getSubject());

        coverService.uploadCover(userId, bookId, file);

        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<Resource> getCover(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        BookCoverService.CoverDownload cover =
                coverService.getCover(userId, bookId);

        MediaType mediaType =
                MediaType.parseMediaType(cover.contentType());

        return ResponseEntity.ok()
                .contentType(mediaType)
                .header(HttpHeaders.CACHE_CONTROL, "private, max-age=3600")
                .body(cover.resource());
    }

    @DeleteMapping
    public ResponseEntity<Void> deleteCover(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        coverService.deleteCover(userId, bookId);

        return ResponseEntity.noContent().build();
    }
}
