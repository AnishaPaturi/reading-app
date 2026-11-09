package com.readingsanctuary.api.storage.enums;

public enum StorageProvider {
    LOCAL,
    S3;

    public static StorageProvider fromString(String value) {
        if (value == null) return LOCAL;
        try {
            return StorageProvider.valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return LOCAL;
        }
    }
}
