package com.readingsanctuary.api.storage.service;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import com.readingsanctuary.api.storage.config.StorageConfig;
import com.readingsanctuary.api.storage.enums.StorageProvider;

@Component
@Primary
public class StorageProviderFactory {

    private final StorageService localStorageService;
    private final StorageService s3StorageService;
    private final StorageConfig storageConfig;

    public StorageProviderFactory(
            @Qualifier("localStorageService") StorageService localStorageService,
            @Qualifier("s3StorageService") StorageService s3StorageService,
            StorageConfig storageConfig) {
        this.localStorageService = localStorageService;
        this.s3StorageService = s3StorageService;
        this.storageConfig = storageConfig;
    }

    public StorageService getActiveStorageService() {
        return getStorageService(storageConfig.getResolvedProvider());
    }

    public StorageService getStorageService(StorageProvider provider) {
        if (provider == StorageProvider.S3) {
            return s3StorageService;
        }
        return localStorageService;
    }
}
