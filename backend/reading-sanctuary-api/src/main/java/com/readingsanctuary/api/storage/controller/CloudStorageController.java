package com.readingsanctuary.api.storage.controller;

import java.io.InputStream;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.readingsanctuary.api.storage.dto.*;
import com.readingsanctuary.api.storage.service.CloudStorageService;
import com.readingsanctuary.api.storage.service.LocalStorageService;

@RestController
@RequestMapping("/api/v1/storage")
public class CloudStorageController {

    private final CloudStorageService cloudStorageService;
    private final LocalStorageService localStorageService;

    public CloudStorageController(
            CloudStorageService cloudStorageService,
            LocalStorageService localStorageService) {
        this.cloudStorageService = cloudStorageService;
        this.localStorageService = localStorageService;
    }

    @PostMapping("/upload-url")
    public ResponseEntity<UploadUrlResponse> requestUploadUrl(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody UploadUrlRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.status(HttpStatus.CREATED).body(cloudStorageService.requestUploadUrl(userId, request));
    }

    @PostMapping("/complete-upload")
    public ResponseEntity<StorageFileResponse> completeUpload(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CompleteUploadRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(cloudStorageService.completeUpload(userId, request));
    }

    @GetMapping("/files/{fileId}/download-url")
    public ResponseEntity<DownloadUrlResponse> getDownloadUrl(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(cloudStorageService.generateDownloadUrl(userId, fileId));
    }

    @DeleteMapping("/files/{fileId}")
    public ResponseEntity<Void> deleteFile(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        cloudStorageService.deleteFile(userId, fileId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/files/{fileId}/status")
    public ResponseEntity<StorageFileResponse> getFileStatus(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID fileId) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(cloudStorageService.getFileStatus(userId, fileId));
    }

    // Local development direct streaming support
    @GetMapping("/local/download")
    public ResponseEntity<Resource> localDownload(@RequestParam("key") String objectKey) {
        InputStream is = localStorageService.download(objectKey);
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(new InputStreamResource(is));
    }

    @PostMapping("/local/upload")
    public ResponseEntity<Void> localUpload(
            @RequestParam("key") String objectKey,
            @RequestParam("file") MultipartFile file) throws Exception {
        localStorageService.upload(objectKey, file.getInputStream(), file.getSize(), file.getContentType());
        return ResponseEntity.ok().build();
    }
}
