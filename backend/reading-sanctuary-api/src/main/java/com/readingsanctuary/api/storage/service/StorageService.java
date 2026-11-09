package com.readingsanctuary.api.storage.service;

import java.io.InputStream;
import java.time.Duration;

public interface StorageService {

    String upload(String objectKey, InputStream inputStream, long contentLength, String contentType);

    InputStream download(String objectKey);

    void delete(String objectKey);

    boolean exists(String objectKey);

    String generateUploadUrl(String objectKey, String contentType, Duration duration);

    String generateDownloadUrl(String objectKey, Duration duration);

    long getObjectSize(String objectKey);
}
