package com.readingsanctuary.api.bookfile.service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class LocalFileStorageService {

    private final Path storageRoot;

    public LocalFileStorageService(
            @Value("${app.storage.local-root}") String storageRoot) throws IOException {

        this.storageRoot = Path.of(storageRoot).toAbsolutePath().normalize();
        Files.createDirectories(this.storageRoot);
    }

    public String store(MultipartFile file, String extension) throws IOException {

        String storageKey = UUID.randomUUID() + "." + extension;
        Path destination = storageRoot.resolve(storageKey).normalize();

        if (!destination.startsWith(storageRoot)) {
            throw new IOException("Invalid storage path");
        }

        try (InputStream inputStream = file.getInputStream()) {
            Files.copy(inputStream, destination, StandardCopyOption.REPLACE_EXISTING);
        }

        return storageKey;
    }

    public Resource load(String storageKey) throws IOException {

        Path filePath = storageRoot.resolve(storageKey).normalize();

        if (!filePath.startsWith(storageRoot)) {
            throw new IOException("Invalid storage path");
        }

        Resource resource = new UrlResource(filePath.toUri());

        if (!resource.exists() || !resource.isReadable()) {
            throw new IOException("File not found or not readable");
        }

        return resource;
    }

    public void delete(String storageKey) throws IOException {

        Path filePath = storageRoot.resolve(storageKey).normalize();

        if (!filePath.startsWith(storageRoot)) {
            throw new IOException("Invalid storage path");
        }

        Files.deleteIfExists(filePath);
    }
}
