package com.readingsanctuary.api.storage.enums;

public enum UploadStatus {
    LOCAL,
    PENDING_UPLOAD,
    UPLOADED,
    VERIFIED,
    FAILED,
    PENDING_DELETE;

    public static UploadStatus fromString(String value) {
        if (value == null) return LOCAL;
        try {
            return UploadStatus.valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return LOCAL;
        }
    }
}
