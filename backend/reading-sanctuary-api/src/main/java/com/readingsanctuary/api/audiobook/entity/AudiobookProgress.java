package com.readingsanctuary.api.audiobook.entity;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "audiobook_progress")
public class AudiobookProgress {

    @Id
    @Column(name = "audiobook_id", nullable = false)
    private UUID audiobookId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "current_track_id")
    private UUID currentTrackId;

    @Column(name = "track_index", nullable = false)
    private Integer trackIndex = 0;

    @Column(name = "position_ms", nullable = false)
    private Long positionMs = 0L;

    @Column(name = "total_duration_ms")
    private Long totalDurationMs = 0L;

    @Column(name = "playback_speed", precision = 3, scale = 2)
    private BigDecimal playbackSpeed = BigDecimal.valueOf(1.00);

    @Column(name = "completed", nullable = false)
    private Boolean completed = false;

    @Column(name = "last_listened_at", nullable = false)
    private OffsetDateTime lastListenedAt;

    protected AudiobookProgress() {}

    public AudiobookProgress(UUID audiobookId, UUID userId, UUID currentTrackId, Integer trackIndex,
                             Long positionMs, Long totalDurationMs, BigDecimal playbackSpeed,
                             Boolean completed) {
        this.audiobookId = audiobookId;
        this.userId = userId;
        this.currentTrackId = currentTrackId;
        this.trackIndex = trackIndex != null ? trackIndex : 0;
        this.positionMs = positionMs != null ? positionMs : 0L;
        this.totalDurationMs = totalDurationMs != null ? totalDurationMs : 0L;
        this.playbackSpeed = playbackSpeed != null ? playbackSpeed : BigDecimal.valueOf(1.00);
        this.completed = completed != null ? completed : false;
        this.lastListenedAt = OffsetDateTime.now();
    }

    public UUID getAudiobookId() { return audiobookId; }
    public UUID getUserId() { return userId; }
    public UUID getCurrentTrackId() { return currentTrackId; }
    public void setCurrentTrackId(UUID currentTrackId) { this.currentTrackId = currentTrackId; }
    public Integer getTrackIndex() { return trackIndex; }
    public void setTrackIndex(Integer trackIndex) { this.trackIndex = trackIndex; }
    public Long getPositionMs() { return positionMs; }
    public void setPositionMs(Long positionMs) { this.positionMs = positionMs; }
    public Long getTotalDurationMs() { return totalDurationMs; }
    public void setTotalDurationMs(Long totalDurationMs) { this.totalDurationMs = totalDurationMs; }
    public BigDecimal getPlaybackSpeed() { return playbackSpeed; }
    public void setPlaybackSpeed(BigDecimal playbackSpeed) { this.playbackSpeed = playbackSpeed; }
    public Boolean getCompleted() { return completed; }
    public void setCompleted(Boolean completed) { this.completed = completed; }
    public OffsetDateTime getLastListenedAt() { return lastListenedAt; }
    public void setLastListenedAt(OffsetDateTime lastListenedAt) { this.lastListenedAt = lastListenedAt; }
}
