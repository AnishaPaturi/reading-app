package com.readingsanctuary.api.tts.entity;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.bookfile.entity.BookFile;

import jakarta.persistence.*;

@Entity
@Table(name = "tts_playback_positions")
public class TtsPlaybackPosition {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_file_id", nullable = false, unique = true)
    private BookFile bookFile;

    @Column(name = "chapter_index", nullable = false)
    private int chapterIndex = 0;

    @Column(name = "chunk_index", nullable = false)
    private int chunkIndex = 0;

    @Column(name = "character_offset", nullable = false)
    private int characterOffset = 0;

    @Column(name = "progress_percentage", nullable = false, precision = 5, scale = 2)
    private BigDecimal progressPercentage = BigDecimal.ZERO;

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
    public int getChapterIndex() { return chapterIndex; }
    public int getChunkIndex() { return chunkIndex; }
    public int getCharacterOffset() { return characterOffset; }
    public BigDecimal getProgressPercentage() { return progressPercentage; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    public void setBook(Book book) { this.book = book; }
    public void setBookFile(BookFile bookFile) { this.bookFile = bookFile; }
    public void setChapterIndex(int chapterIndex) { this.chapterIndex = chapterIndex; }
    public void setChunkIndex(int chunkIndex) { this.chunkIndex = chunkIndex; }
    public void setCharacterOffset(int characterOffset) { this.characterOffset = characterOffset; }
    public void setProgressPercentage(BigDecimal progressPercentage) { this.progressPercentage = progressPercentage; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
