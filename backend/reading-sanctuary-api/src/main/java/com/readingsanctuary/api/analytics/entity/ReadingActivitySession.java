package com.readingsanctuary.api.analytics.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.analytics.enums.ActivityType;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.user.entity.User;

import jakarta.persistence.*;

@Entity
@Table(name = "reading_activity_sessions")
public class ReadingActivitySession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "book_id")
    private Book book;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "book_file_id")
    private BookFile bookFile;

    @Enumerated(EnumType.STRING)
    @Column(name = "activity_type", nullable = false, length = 20)
    private ActivityType activityType;

    @Column(name = "started_at", nullable = false)
    private OffsetDateTime startedAt;

    @Column(name = "ended_at")
    private OffsetDateTime endedAt;

    @Column(name = "last_heartbeat_at", nullable = false)
    private OffsetDateTime lastHeartbeatAt;

    @Column(name = "duration_seconds", nullable = false)
    private int durationSeconds = 0;

    @Column(name = "start_progress")
    private Double startProgress;

    @Column(name = "end_progress")
    private Double endProgress;

    @Column(name = "pages_advanced", nullable = false)
    private int pagesAdvanced = 0;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        OffsetDateTime now = OffsetDateTime.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
        if (startedAt == null) {
            startedAt = now;
        }
        if (lastHeartbeatAt == null) {
            lastHeartbeatAt = now;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public Book getBook() { return book; }
    public void setBook(Book book) { this.book = book; }
    public BookFile getBookFile() { return bookFile; }
    public void setBookFile(BookFile bookFile) { this.bookFile = bookFile; }
    public ActivityType getActivityType() { return activityType; }
    public void setActivityType(ActivityType activityType) { this.activityType = activityType; }
    public OffsetDateTime getStartedAt() { return startedAt; }
    public void setStartedAt(OffsetDateTime startedAt) { this.startedAt = startedAt; }
    public OffsetDateTime getEndedAt() { return endedAt; }
    public void setEndedAt(OffsetDateTime endedAt) { this.endedAt = endedAt; }
    public OffsetDateTime getLastHeartbeatAt() { return lastHeartbeatAt; }
    public void setLastHeartbeatAt(OffsetDateTime lastHeartbeatAt) { this.lastHeartbeatAt = lastHeartbeatAt; }
    public int getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(int durationSeconds) { this.durationSeconds = durationSeconds; }
    public Double getStartProgress() { return startProgress; }
    public void setStartProgress(Double startProgress) { this.startProgress = startProgress; }
    public Double getEndProgress() { return endProgress; }
    public void setEndProgress(Double endProgress) { this.endProgress = endProgress; }
    public int getPagesAdvanced() { return pagesAdvanced; }
    public void setPagesAdvanced(int pagesAdvanced) { this.pagesAdvanced = pagesAdvanced; }
    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }
}
