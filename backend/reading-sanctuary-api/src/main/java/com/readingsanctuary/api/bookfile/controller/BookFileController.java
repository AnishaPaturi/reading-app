package com.readingsanctuary.api.bookfile.controller;

import java.util.List;
import java.util.UUID;

import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.readingsanctuary.api.bookfile.dto.BookFileResponse;
import com.readingsanctuary.api.bookfile.service.BookFileService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/files")
public class BookFileController {

    private final BookFileService bookFileService;

    public BookFileController(BookFileService bookFileService) {
        this.bookFileService = bookFileService;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<BookFileResponse> upload(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @RequestParam("file") MultipartFile file) {

        UUID userId = UUID.fromString(jwt.getSubject());

        BookFileResponse response =
                bookFileService.upload(userId, bookId, file);

        return ResponseEntity.status(201).body(response);
    }

    @GetMapping
    public ResponseEntity<List<BookFileResponse>> getFiles(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        return ResponseEntity.ok(
                bookFileService.getFiles(userId, bookId));
    }

    @GetMapping("/{fileId}")
    public ResponseEntity<Resource> download(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        Resource resource =
                bookFileService.download(userId, bookId, fileId);

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(resource.getFilename())
                                .build()
                                .toString()
                )
                .body(resource);
    }

    @DeleteMapping("/{fileId}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());

        bookFileService.delete(userId, bookId, fileId);

        return ResponseEntity.noContent().build();
    }
}
