package com.readingsanctuary.api.storage.service;

import java.io.InputStream;
import java.security.MessageDigest;
import java.util.HexFormat;

import org.springframework.stereotype.Service;

@Service
public class FileIntegrityService {

    public String computeSha256(InputStream inputStream) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] buffer = new byte[8192];
            int read;
            while ((read = inputStream.read(buffer)) != -1) {
                digest.update(buffer, 0, read);
            }
            return HexFormat.of().formatHex(digest.digest());
        } catch (Exception e) {
            throw new RuntimeException("Failed to compute SHA-256 checksum", e);
        }
    }

    public String computeSha256(byte[] data) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(data));
        } catch (Exception e) {
            throw new RuntimeException("Failed to compute SHA-256 checksum", e);
        }
    }

    public boolean verifyChecksum(String calculatedChecksum, String expectedChecksum) {
        if (calculatedChecksum == null || expectedChecksum == null) {
            return false;
        }
        return calculatedChecksum.trim().equalsIgnoreCase(expectedChecksum.trim());
    }
}
