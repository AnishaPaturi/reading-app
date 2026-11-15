package com.readingsanctuary.api.audiobook.entity;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "audiobooks")
public class Audiobook {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "title", nullable = false, length = 500)
    private String title;

    @Column(name = "author", length = 300)
    private String author;

    @Column(name = "narrator", length = 300)
    private String narrator;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "cover_path", columnDefinition = "TEXT")
    private String coverPath;

    @Column(name = "folder_path", columnDefinition = "TEXT")
    private String folderPath;

    @Column(name = "total_duration_ms")
    private Long totalDurationMs = 0L;

    @Column(name = "total_tracks")
    private Integer totalTracks = 1;

    @Column(name = "status", nullable = false, length = 30)
    private String status = "notStarted";

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @OneToMany(mappedBy = "audiobook", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AudioTrack> tracks = new ArrayList<>();

    protected Audiobook() {}

    public Audiobook(UUID id, UUID userId, String title, String author, String narrator,
                     String description, String coverPath, String folderPath,
                     Long totalDurationMs, Integer totalTracks, String status) {
        this.id = id != null ? id : UUID.randomUUID();
        this.userId = userId;
        this.title = title;
        this.author = author;
        this.narrator = narrator;
        this.description = description;
        this.coverPath = coverPath;
        this.folderPath = folderPath;
        this.totalDurationMs = totalDurationMs != null ? totalDurationMs : 0L;
        this.totalTracks = totalTracks != null ? totalTracks : 1;
        this.status = status != null ? status : "notStarted";
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getAuthor() { return author; }
    public void setAuthor(String author) { this.author = author; }
    public String getNarrator() { return narrator; }
    public void setNarrator(String narrator) { this.narrator = narrator; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getCoverPath() { return coverPath; }
    public void setCoverPath(String coverPath) { this.coverPath = coverPath; }
    public String getFolderPath() { return folderPath; }
    public void setFolderPath(String folderPath) { this.folderPath = folderPath; }
    public Long getTotalDurationMs() { return totalDurationMs; }
    public void setTotalDurationMs(Long totalDurationMs) { this.totalDurationMs = totalDurationMs; }
    public Integer getTotalTracks() { return totalTracks; }
    public void setTotalTracks(Integer totalTracks) { this.totalTracks = totalTracks; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public List<AudioTrack> getTracks() { return tracks; }
    public void setTracks(List<AudioTrack> tracks) { this.tracks = tracks; }
}
