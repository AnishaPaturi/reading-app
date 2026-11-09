package com.readingsanctuary.api.sync.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "sync_processed_changes")
public class SyncProcessedChange {

    @Id
    @Column(name = "client_change_id", length = 100)
    private String clientChangeId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "device_id", nullable = false)
    private UUID deviceId;

    @Column(name = "processed_at", nullable = false, updatable = false)
    private OffsetDateTime processedAt;

    public SyncProcessedChange() {
    }

    public SyncProcessedChange(String clientChangeId, UUID userId, UUID deviceId) {
        this.clientChangeId = clientChangeId;
        this.userId = userId;
        this.deviceId = deviceId;
        this.processedAt = OffsetDateTime.now();
    }

    @PrePersist
    protected void onCreate() {
        if (processedAt == null) {
            processedAt = OffsetDateTime.now();
        }
    }

    public String getClientChangeId() { return clientChangeId; }
    public UUID getUserId() { return userId; }
    public UUID getDeviceId() { return deviceId; }
    public OffsetDateTime getProcessedAt() { return processedAt; }

    public void setClientChangeId(String clientChangeId) { this.clientChangeId = clientChangeId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public void setDeviceId(UUID deviceId) { this.deviceId = deviceId; }
}
