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

    public String storeBytes(byte[] bytes, String extension) throws IOException {

        String storageKey = UUID.randomUUID() + "." + extension;
        Path destination = storageRoot.resolve(storageKey).normalize();

        if (!destination.startsWith(storageRoot)) {
            throw new IOException("Invalid storage path");
        }

        Files.write(destination, bytes);

        return storageKey;
    }

    public Resource load(String storageKey) throws IOException {

        Path filePath = storageRoot.resolve(storageKey).normalize();

        if (filePath.startsWith(storageRoot) && Files.exists(filePath) && Files.isReadable(filePath)) {
            return new UrlResource(filePath.toUri());
        }

        // Check under books/
        Path inBooks = storageRoot.resolve("books").resolve(storageKey).normalize();
        if (inBooks.startsWith(storageRoot) && Files.exists(inBooks) && Files.isReadable(inBooks)) {
            return new UrlResource(inBooks.toUri());
        }

        // Check under pending/
        Path inPending = storageRoot.resolve("pending").resolve(storageKey).normalize();
        if (inPending.startsWith(storageRoot) && Files.exists(inPending) && Files.isReadable(inPending)) {
            return new UrlResource(inPending.toUri());
        }

        // Check base filename under books/ and pending/
        String baseName = Path.of(storageKey).getFileName().toString();
        Path inBooksBase = storageRoot.resolve("books").resolve(baseName).normalize();
        if (inBooksBase.startsWith(storageRoot) && Files.exists(inBooksBase) && Files.isReadable(inBooksBase)) {
            return new UrlResource(inBooksBase.toUri());
        }

        Path inPendingBase = storageRoot.resolve("pending").resolve(baseName).normalize();
        if (inPendingBase.startsWith(storageRoot) && Files.exists(inPendingBase) && Files.isReadable(inPendingBase)) {
            return new UrlResource(inPendingBase.toUri());
        }

        throw new IOException("File not found or not readable: " + storageKey);
    }

    public void delete(String storageKey) throws IOException {

        Path filePath = storageRoot.resolve(storageKey).normalize();

        if (!filePath.startsWith(storageRoot)) {
            throw new IOException("Invalid storage path");
        }

        Files.deleteIfExists(filePath);
    }
}
