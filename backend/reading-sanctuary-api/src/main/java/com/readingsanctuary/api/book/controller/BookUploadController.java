package com.readingsanctuary.api.book.controller;

import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.readingsanctuary.api.book.dto.BookResponse;
import com.readingsanctuary.api.book.dto.BookUploadResponse;
import com.readingsanctuary.api.book.dto.ConfirmBookRequest;
import com.readingsanctuary.api.book.service.BookUploadService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/books")
public class BookUploadController {

    private final BookUploadService bookUploadService;

    public BookUploadController(BookUploadService bookUploadService) {
        this.bookUploadService = bookUploadService;
    }

    /**
     * Stage 1: Upload a book file (PDF, EPUB, MP3, M4B) and scan its metadata.
     * Derives user identity strictly from the authenticated JWT principal.
     */
    @PostMapping(
            value = "/upload",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<BookUploadResponse> uploadBook(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getSubject());
        BookUploadResponse response = bookUploadService.uploadAndExtract(file, userId);
        return ResponseEntity.ok(response);
    }

    /**
     * Stage 2: Confirm edited details, move file to permanent storage, and persist the book.
     */
    @PostMapping(
            value = "/confirm",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<BookResponse> confirmBook(
            @Valid @RequestBody ConfirmBookRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        UUID userId = UUID.fromString(jwt.getSubject());
        BookResponse response = bookUploadService.confirmBook(request, userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
