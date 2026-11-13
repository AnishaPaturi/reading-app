package com.readingsanctuary.api.book.service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.Locale;
import java.util.UUID;
import java.util.stream.Stream;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class BookStorageService {

    private final Path rootDir;
    private final Path pendingDir;
    private final Path booksDir;

    public BookStorageService(
            @Value("${app.storage.local-root:./reading-sanctuary-storage}") String storageRoot) throws IOException {

        this.rootDir = Path.of(storageRoot).toAbsolutePath().normalize();
        this.pendingDir = rootDir.resolve("pending").normalize();
        this.booksDir = rootDir.resolve("books").normalize();

        Files.createDirectories(this.pendingDir);
        Files.createDirectories(this.booksDir);
    }

    /**
     * Stores an uploaded file temporarily into the pending storage area.
     * Generates a UUID-based key to prevent collisions and path traversal.
     */
    public String storePending(MultipartFile file, String extension) throws IOException {
        String cleanExt = extension.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]", "");
        String key = "pending/" + UUID.randomUUID() + "." + cleanExt;
        Path destination = rootDir.resolve(key).normalize();

        if (!destination.startsWith(pendingDir)) {
            throw new IOException("Invalid storage path destination");
        }

        try (InputStream in = file.getInputStream()) {
            Files.copy(in, destination, StandardCopyOption.REPLACE_EXISTING);
        }

        return key;
    }

    /**
     * Resolves the actual File/Path for a storage key.
     */
    public Path getPath(String storageKey) throws IOException {
        Path resolved = rootDir.resolve(storageKey).normalize();
        if (!resolved.startsWith(rootDir)) {
            throw new IOException("Path traversal attempt detected");
        }
        return resolved;
    }

    /**
     * Promotes a file from pending to permanent storage under books/.
     * Returns the permanent storage key.
     */
    public String promoteToPermanent(String pendingKey) throws IOException {
        Path source = rootDir.resolve(pendingKey).normalize();
        if (!source.startsWith(pendingDir) || !Files.exists(source)) {
            throw new IOException("Pending file not found: " + pendingKey);
        }

        String fileName = source.getFileName().toString();
        String permanentKey = "books/" + fileName;
        Path target = rootDir.resolve(permanentKey).normalize();

        if (!target.startsWith(booksDir)) {
            throw new IOException("Invalid target storage path");
        }

        Files.move(source, target, StandardCopyOption.REPLACE_EXISTING);
        return permanentKey;
    }

    /**
     * Loads a file resource by its storage key.
     */
    public Resource load(String storageKey) throws IOException {
        Path filePath = rootDir.resolve(storageKey).normalize();

        if (!filePath.startsWith(rootDir)) {
            throw new IOException("Invalid storage path");
        }

        Resource resource = new UrlResource(filePath.toUri());
        if (!resource.exists() || !resource.isReadable()) {
            throw new IOException("File not found or not readable: " + storageKey);
        }

        return resource;
    }

    /**
     * Deletes a file by its storage key.
     */
    public void delete(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) {
            return;
        }
        try {
            Path filePath = rootDir.resolve(storageKey).normalize();
            if (filePath.startsWith(rootDir)) {
                Files.deleteIfExists(filePath);
            }
        } catch (IOException ignored) {
            // Log in production
        }
    }

    /**
     * Cleans up pending files older than maxAgeMillis.
     */
    public void cleanExpiredPendingFiles(long maxAgeMillis) {
        long cutoffTime = System.currentTimeMillis() - maxAgeMillis;
        try (Stream<Path> stream = Files.list(pendingDir)) {
            stream.filter(Files::isRegularFile).forEach(path -> {
                try {
                    long lastModified = Files.getLastModifiedTime(path).toMillis();
                    if (lastModified < cutoffTime) {
                        Files.deleteIfExists(path);
                    }
                } catch (IOException ignored) {}
            });
        } catch (IOException ignored) {}
    }
}
