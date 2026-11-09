package com.readingsanctuary.api.audiobook.entity;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.bookfile.entity.BookFile;

import jakarta.persistence.*;

@Entity
@Table(name = "audiobook_playback_positions")
public class AudiobookPlaybackPosition {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_file_id", nullable = false, unique = true)
    private BookFile bookFile;

    @Column(name = "position_ms", nullable = false)
    private long positionMs = 0;

    @Column(name = "duration_ms", nullable = false)
    private long durationMs = 0;

    @Column(name = "playback_speed", nullable = false, precision = 3, scale = 2)
    private BigDecimal playbackSpeed = new BigDecimal("1.00");

    @Column(name = "is_completed", nullable = false)
    private boolean isCompleted = false;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    @PreUpdate
    protected void onSave() {
        updatedAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public Book getBook() { return book; }
    public BookFile getBookFile() { return bookFile; }
    public long getPositionMs() { return positionMs; }
    public long getDurationMs() { return durationMs; }
    public BigDecimal getPlaybackSpeed() { return playbackSpeed; }
    public boolean isCompleted() { return isCompleted; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    public void setBook(Book book) { this.book = book; }
    public void setBookFile(BookFile bookFile) { this.bookFile = bookFile; }
    public void setPositionMs(long positionMs) { this.positionMs = positionMs; }
    public void setDurationMs(long durationMs) { this.durationMs = durationMs; }
    public void setPlaybackSpeed(BigDecimal playbackSpeed) { this.playbackSpeed = playbackSpeed; }
    public void setCompleted(boolean completed) { isCompleted = completed; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
