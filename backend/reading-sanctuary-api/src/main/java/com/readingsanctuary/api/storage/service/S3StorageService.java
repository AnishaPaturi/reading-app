package com.readingsanctuary.api.storage.service;

import java.io.InputStream;
import java.time.Duration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.readingsanctuary.api.storage.config.StorageConfig;

import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

@Service("s3StorageService")
public class S3StorageService implements StorageService {

    private static final Logger log = LoggerFactory.getLogger(S3StorageService.class);

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    private final StorageConfig storageConfig;

    public S3StorageService(
            S3Client s3Client,
            S3Presigner s3Presigner,
            StorageConfig storageConfig) {
        this.s3Client = s3Client;
        this.s3Presigner = s3Presigner;
        this.storageConfig = storageConfig;
    }

    private String getBucket() {
        return storageConfig.getS3().getBucket();
    }

    @Override
    public String upload(String objectKey, InputStream inputStream, long contentLength, String contentType) {
        PutObjectRequest request = PutObjectRequest.builder()
                .bucket(getBucket())
                .key(objectKey)
                .contentType(contentType)
                .contentLength(contentLength)
                .build();

        s3Client.putObject(request, RequestBody.fromInputStream(inputStream, contentLength));
        return objectKey;
    }

    @Override
    public InputStream download(String objectKey) {
        GetObjectRequest request = GetObjectRequest.builder()
                .bucket(getBucket())
                .key(objectKey)
                .build();

        return s3Client.getObject(request);
    }

    @Override
    public void delete(String objectKey) {
        try {
            DeleteObjectRequest request = DeleteObjectRequest.builder()
                    .bucket(getBucket())
                    .key(objectKey)
                    .build();

            s3Client.deleteObject(request);
        } catch (Exception e) {
            log.warn("Failed to delete S3 object: {} from bucket: {}", objectKey, getBucket(), e);
        }
    }

    @Override
    public boolean exists(String objectKey) {
        try {
            HeadObjectRequest request = HeadObjectRequest.builder()
                    .bucket(getBucket())
                    .key(objectKey)
                    .build();

            s3Client.headObject(request);
            return true;
        } catch (NoSuchKeyException e) {
            return false;
        } catch (S3Exception e) {
            if (e.statusCode() == 404) {
                return false;
            }
            log.warn("Error checking existence for S3 object: {}", objectKey, e);
            return false;
        }
    }

    @Override
    public String generateUploadUrl(String objectKey, String contentType, Duration duration) {
        PutObjectRequest objectRequest = PutObjectRequest.builder()
                .bucket(getBucket())
                .key(objectKey)
                .contentType(contentType)
                .build();

        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(duration)
                .putObjectRequest(objectRequest)
                .build();

        return s3Presigner.presignPutObject(presignRequest).url().toString();
    }

    @Override
    public String generateDownloadUrl(String objectKey, Duration duration) {
        GetObjectRequest objectRequest = GetObjectRequest.builder()
                .bucket(getBucket())
                .key(objectKey)
                .build();

        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(duration)
                .getObjectRequest(objectRequest)
                .build();

        return s3Presigner.presignGetObject(presignRequest).url().toString();
    }

    @Override
    public long getObjectSize(String objectKey) {
        try {
            HeadObjectRequest request = HeadObjectRequest.builder()
                    .bucket(getBucket())
                    .key(objectKey)
                    .build();

            HeadObjectResponse response = s3Client.headObject(request);
            return response.contentLength();
        } catch (Exception e) {
            return 0;
        }
    }
}
