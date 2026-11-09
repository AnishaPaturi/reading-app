package com.readingsanctuary.api.sync.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.user.entity.User;

import jakarta.persistence.*;

@Entity
@Table(name = "sync_devices")
public class SyncDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "device_name", nullable = false, length = 150)
    private String deviceName;

    @Column(name = "platform", nullable = false, length = 30)
    private String platform;

    @Column(name = "last_sync_cursor", nullable = false)
    private long lastSyncCursor = 0;

    @Column(name = "last_seen_at")
    private OffsetDateTime lastSeenAt;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public SyncDevice() {
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
        lastSeenAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public User getUser() { return user; }
    public String getDeviceName() { return deviceName; }
    public String getPlatform() { return platform; }
    public long getLastSyncCursor() { return lastSyncCursor; }
    public OffsetDateTime getLastSeenAt() { return lastSeenAt; }
    public boolean isActive() { return isActive; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    public void setUser(User user) { this.user = user; }
    public void setDeviceName(String deviceName) { this.deviceName = deviceName; }
    public void setPlatform(String platform) { this.platform = platform; }
    public void setLastSyncCursor(long lastSyncCursor) { this.lastSyncCursor = lastSyncCursor; }
    public void setLastSeenAt(OffsetDateTime lastSeenAt) { this.lastSeenAt = lastSeenAt; }
    public void setActive(boolean active) { isActive = active; }
}
