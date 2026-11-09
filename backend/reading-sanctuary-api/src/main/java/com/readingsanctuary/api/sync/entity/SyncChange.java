package com.readingsanctuary.api.sync.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "sync_change_log")
public class SyncChange {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "cursor", nullable = false)
    private long cursor;

    @Column(name = "entity_type", nullable = false, length = 50)
    private String entityType;

    @Column(name = "entity_id", nullable = false, length = 100)
    private String entityId;

    @Column(name = "operation", nullable = false, length = 20)
    private String operation;

    @Column(name = "entity_version", nullable = false)
    private long entityVersion = 1;

    @Column(name = "payload", columnDefinition = "TEXT")
    private String payload;

    @Column(name = "changed_at", nullable = false, updatable = false)
    private OffsetDateTime changedAt;

    public SyncChange() {
    }

    @PrePersist
    protected void onCreate() {
        if (changedAt == null) {
            changedAt = OffsetDateTime.now();
        }
    }

    public Long getId() { return id; }
    public UUID getUserId() { return userId; }
    public long getCursor() { return cursor; }
    public String getEntityType() { return entityType; }
    public String getEntityId() { return entityId; }
    public String getOperation() { return operation; }
    public long getEntityVersion() { return entityVersion; }
    public String getPayload() { return payload; }
    public OffsetDateTime getChangedAt() { return changedAt; }

    public void setUserId(UUID userId) { this.userId = userId; }
    public void setCursor(long cursor) { this.cursor = cursor; }
    public void setEntityType(String entityType) { this.entityType = entityType; }
    public void setEntityId(String entityId) { this.entityId = entityId; }
    public void setOperation(String operation) { this.operation = operation; }
    public void setEntityVersion(long entityVersion) { this.entityVersion = entityVersion; }
    public void setPayload(String payload) { this.payload = payload; }
    public void setChangedAt(OffsetDateTime changedAt) { this.changedAt = changedAt; }
}
