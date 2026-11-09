package com.readingsanctuary.api.storage.service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Duration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service("localStorageService")
public class LocalStorageService implements StorageService {

    private static final Logger log = LoggerFactory.getLogger(LocalStorageService.class);
    private final Path storageRoot;

    public LocalStorageService(
            @Value("${app.storage.local-root:./reading-sanctuary-storage}") String storageRoot) throws IOException {
        this.storageRoot = Path.of(storageRoot).toAbsolutePath().normalize();
        Files.createDirectories(this.storageRoot);
    }

    private Path resolveSafePath(String objectKey) {
        Path resolved = storageRoot.resolve(objectKey).normalize();
        if (!resolved.startsWith(storageRoot)) {
            throw new IllegalArgumentException("Path traversal attempt detected: " + objectKey);
        }
        return resolved;
    }

    @Override
    public String upload(String objectKey, InputStream inputStream, long contentLength, String contentType) {
        Path destination = resolveSafePath(objectKey);
        try {
            if (destination.getParent() != null) {
                Files.createDirectories(destination.getParent());
            }
            Files.copy(inputStream, destination, StandardCopyOption.REPLACE_EXISTING);
            return objectKey;
        } catch (IOException e) {
            throw new RuntimeException("Failed to upload local file: " + objectKey, e);
        }
    }

    @Override
    public InputStream download(String objectKey) {
        Path filePath = resolveSafePath(objectKey);
        if (!Files.exists(filePath) || !Files.isReadable(filePath)) {
            throw new RuntimeException("Local file not found or not readable: " + objectKey);
        }
        try {
            return Files.newInputStream(filePath);
        } catch (IOException e) {
            throw new RuntimeException("Failed to open local file stream: " + objectKey, e);
        }
    }

    @Override
    public void delete(String objectKey) {
        Path filePath = resolveSafePath(objectKey);
        try {
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
            log.warn("Could not delete local file: {}", objectKey, e);
        }
    }

    @Override
    public boolean exists(String objectKey) {
        Path filePath = resolveSafePath(objectKey);
        return Files.exists(filePath);
    }

    @Override
    public String generateUploadUrl(String objectKey, String contentType, Duration duration) {
        // Return relative or mock presigned URL for local testing
        return "/api/v1/storage/local/upload?key=" + objectKey;
    }

    @Override
    public String generateDownloadUrl(String objectKey, Duration duration) {
        return "/api/v1/storage/local/download?key=" + objectKey;
    }

    @Override
    public long getObjectSize(String objectKey) {
        Path filePath = resolveSafePath(objectKey);
        try {
            return Files.size(filePath);
        } catch (IOException e) {
            return 0;
        }
    }
}
