package com.readingsanctuary.api.storage.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
public class S3Config {

    private static final Logger log = LoggerFactory.getLogger(S3Config.class);
    private final StorageConfig storageConfig;

    public S3Config(StorageConfig storageConfig) {
        this.storageConfig = storageConfig;
    }

    @Bean
    @ConditionalOnMissingBean
    public S3Client s3Client() {
        String regionStr = storageConfig.getS3().getRegion();
        if (regionStr == null || regionStr.isBlank()) {
            regionStr = "us-east-1";
        }

        try {
            return S3Client.builder()
                    .region(Region.of(regionStr))
                    .credentialsProvider(DefaultCredentialsProvider.create())
                    .build();
        } catch (Exception e) {
            log.warn("Could not initialize real S3Client with DefaultCredentialsProvider (fallback may be in use): {}", e.getMessage());
            // Create a minimal client configured with anonymous/dummy credentials for local fallback
            return S3Client.builder()
                    .region(Region.of(regionStr))
                    .credentialsProvider(software.amazon.awssdk.auth.credentials.AnonymousCredentialsProvider.create())
                    .build();
        }
    }

    @Bean
    @ConditionalOnMissingBean
    public S3Presigner s3Presigner() {
        String regionStr = storageConfig.getS3().getRegion();
        if (regionStr == null || regionStr.isBlank()) {
            regionStr = "us-east-1";
        }

        try {
            return S3Presigner.builder()
                    .region(Region.of(regionStr))
                    .credentialsProvider(DefaultCredentialsProvider.create())
                    .build();
        } catch (Exception e) {
            log.warn("Could not initialize real S3Presigner with DefaultCredentialsProvider: {}", e.getMessage());
            return S3Presigner.builder()
                    .region(Region.of(regionStr))
                    .credentialsProvider(software.amazon.awssdk.auth.credentials.AnonymousCredentialsProvider.create())
                    .build();
        }
    }
}
