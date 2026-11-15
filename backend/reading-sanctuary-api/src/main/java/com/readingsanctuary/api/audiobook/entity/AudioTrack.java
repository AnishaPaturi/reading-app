package com.readingsanctuary.api.audiobook.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "audiobook_tracks")
public class AudioTrack {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "audiobook_id", nullable = false)
    private Audiobook audiobook;

    @Column(name = "file_name", nullable = false, length = 500)
    private String fileName;

    @Column(name = "track_order", nullable = false)
    private Integer trackOrder;

    @Column(name = "duration_ms")
    private Long durationMs = 0L;

    @Column(name = "format", nullable = false, length = 20)
    private String format;

    @Column(name = "chapter_title", length = 300)
    private String chapterTitle;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    protected AudioTrack() {}

    public AudioTrack(UUID id, Audiobook audiobook, String fileName, Integer trackOrder,
                      Long durationMs, String format, String chapterTitle) {
        this.id = id != null ? id : UUID.randomUUID();
        this.audiobook = audiobook;
        this.fileName = fileName;
        this.trackOrder = trackOrder != null ? trackOrder : 1;
        this.durationMs = durationMs != null ? durationMs : 0L;
        this.format = format != null ? format : "MP3";
        this.chapterTitle = chapterTitle;
        this.createdAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public Audiobook getAudiobook() { return audiobook; }
    public void setAudiobook(Audiobook audiobook) { this.audiobook = audiobook; }
    public String getFileName() { return fileName; }
    public Integer getTrackOrder() { return trackOrder; }
    public Long getDurationMs() { return durationMs; }
    public String getFormat() { return format; }
    public String getChapterTitle() { return chapterTitle; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
}
