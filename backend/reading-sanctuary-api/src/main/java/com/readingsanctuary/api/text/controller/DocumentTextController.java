package com.readingsanctuary.api.text.controller;

import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.readingsanctuary.api.text.dto.ExtractedTextResponse;
import com.readingsanctuary.api.text.service.DocumentTextExtractionService;

@RestController
@RequestMapping("/api/v1/books/{bookId}/files/{fileId}/text")
public class DocumentTextController {

    private final DocumentTextExtractionService textExtractionService;

    public DocumentTextController(DocumentTextExtractionService textExtractionService) {
        this.textExtractionService = textExtractionService;
    }

    @GetMapping
    public ResponseEntity<ExtractedTextResponse> getText(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID bookId,
            @PathVariable UUID fileId,
            @RequestParam(defaultValue = "1") int chapter) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(textExtractionService.extractText(userId, bookId, fileId, chapter));
    }
}
