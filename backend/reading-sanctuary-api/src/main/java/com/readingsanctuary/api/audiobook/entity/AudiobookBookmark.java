package com.readingsanctuary.api.audiobook.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "audiobook_bookmarks")
public class AudiobookBookmark {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "audiobook_id", nullable = false)
    private UUID audiobookId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "track_id")
    private UUID trackId;

    @Column(name = "track_index", nullable = false)
    private Integer trackIndex = 0;

    @Column(name = "position_ms", nullable = false)
    private Long positionMs = 0L;

    @Column(name = "title", nullable = false, length = 250)
    private String title;

    @Column(name = "note", columnDefinition = "TEXT")
    private String note;

    @Column(name = "category", nullable = false, length = 30)
    private String category = "note";

    @Column(name = "is_favorite", nullable = false)
    private Boolean favorite = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    protected AudiobookBookmark() {}

    public AudiobookBookmark(UUID id, UUID audiobookId, UUID userId, UUID trackId,
                             Integer trackIndex, Long positionMs, String title, String note,
                             String category, Boolean favorite) {
        this.id = id != null ? id : UUID.randomUUID();
        this.audiobookId = audiobookId;
        this.userId = userId;
        this.trackId = trackId;
        this.trackIndex = trackIndex != null ? trackIndex : 0;
        this.positionMs = positionMs != null ? positionMs : 0L;
        this.title = title != null ? title : "Bookmark";
        this.note = note;
        this.category = category != null ? category : "note";
        this.favorite = favorite != null ? favorite : false;
        this.createdAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public UUID getAudiobookId() { return audiobookId; }
    public UUID getUserId() { return userId; }
    public UUID getTrackId() { return trackId; }
    public Integer getTrackIndex() { return trackIndex; }
    public Long getPositionMs() { return positionMs; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public Boolean getFavorite() { return favorite; }
    public void setFavorite(Boolean favorite) { this.favorite = favorite; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
}
