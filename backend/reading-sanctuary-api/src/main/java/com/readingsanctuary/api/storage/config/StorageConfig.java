package com.readingsanctuary.api.storage.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import com.readingsanctuary.api.storage.enums.StorageProvider;

@Configuration
@ConfigurationProperties(prefix = "app.storage")
public class StorageConfig {

    private String provider = "local";
    private String localRoot = "./reading-sanctuary-storage";
    private long coverMaxSize = 5242880;
    private S3Properties s3 = new S3Properties();

    public StorageProvider getResolvedProvider() {
        return StorageProvider.fromString(provider);
    }

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getLocalRoot() { return localRoot; }
    public void setLocalRoot(String localRoot) { this.localRoot = localRoot; }

    public long getCoverMaxSize() { return coverMaxSize; }
    public void setCoverMaxSize(long coverMaxSize) { this.coverMaxSize = coverMaxSize; }

    public S3Properties getS3() { return s3; }
    public void setS3(S3Properties s3) { this.s3 = s3; }

    public static class S3Properties {
        private String bucket = "";
        private String region = "us-east-1";
        private int presignedUrlExpirationMinutes = 15;

        public String getBucket() { return bucket; }
        public void setBucket(String bucket) { this.bucket = bucket; }

        public String getRegion() { return region; }
        public void setRegion(String region) { this.region = region; }

        public int getPresignedUrlExpirationMinutes() { return presignedUrlExpirationMinutes; }
        public void setPresignedUrlExpirationMinutes(int presignedUrlExpirationMinutes) {
            this.presignedUrlExpirationMinutes = presignedUrlExpirationMinutes;
        }
    }
}
