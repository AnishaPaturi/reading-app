package com.readingsanctuary.api.audiobook.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "audiobook_listening_sessions")
public class AudiobookListeningSession {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "audiobook_id", nullable = false)
    private UUID audiobookId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "started_at", nullable = false)
    private OffsetDateTime startedAt;

    @Column(name = "ended_at")
    private OffsetDateTime endedAt;

    @Column(name = "actual_listening_ms")
    private Long actualListeningMs = 0L;

    protected AudiobookListeningSession() {}

    public AudiobookListeningSession(UUID id, UUID audiobookId, UUID userId,
                                    OffsetDateTime startedAt, OffsetDateTime endedAt,
                                    Long actualListeningMs) {
        this.id = id != null ? id : UUID.randomUUID();
        this.audiobookId = audiobookId;
        this.userId = userId;
        this.startedAt = startedAt != null ? startedAt : OffsetDateTime.now();
        this.endedAt = endedAt;
        this.actualListeningMs = actualListeningMs != null ? actualListeningMs : 0L;
    }

    public UUID getId() { return id; }
    public UUID getAudiobookId() { return audiobookId; }
    public UUID getUserId() { return userId; }
    public OffsetDateTime getStartedAt() { return startedAt; }
    public OffsetDateTime getEndedAt() { return endedAt; }
    public void setEndedAt(OffsetDateTime endedAt) { this.endedAt = endedAt; }
    public Long getActualListeningMs() { return actualListeningMs; }
    public void setActualListeningMs(Long actualListeningMs) { this.actualListeningMs = actualListeningMs; }
}
