package com.readingsanctuary.api.readingprogress.entity;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.user.entity.User;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.*;

@Entity
@Table(
    name = "reading_progress",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uq_user_book_file",
            columnNames = {"user_id", "book_file_id"}
        )
    }
)
public class ReadingProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_file_id", nullable = false)
    private BookFile bookFile;

    @Column(nullable = false, length = 20)
    private String format;

    @Column(name = "current_page")
    private Integer currentPage;

    @Column(name = "total_pages")
    private Integer totalPages;

    @Column(name = "chapter_href", columnDefinition = "TEXT")
    private String chapterHref;

    @Column(name = "epub_cfi", columnDefinition = "TEXT")
    private String epubCfi;

    @Column(name = "audio_position_ms")
    private Long audioPositionMs;

    @Column(name = "audio_duration_ms")
    private Long audioDurationMs;

    @Column(
        name = "progress_percentage",
        nullable = false,
        precision = 6,
        scale = 3
    )
    private BigDecimal progressPercentage = BigDecimal.ZERO;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(
        name = "position_data",
        columnDefinition = "jsonb"
    )
    private String positionData = "{}";

    @Column(name = "last_opened_at")
    private OffsetDateTime lastOpenedAt;

    @Column(name = "client_updated_at")
    private OffsetDateTime clientUpdatedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public ReadingProgress() {
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = OffsetDateTime.now();
        }
        if (lastOpenedAt == null) {
            lastOpenedAt = OffsetDateTime.now();
        }
        if (positionData == null || positionData.isBlank()) {
            positionData = "{}";
        }
        if (progressPercentage == null) {
            progressPercentage = BigDecimal.ZERO;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
        if (positionData == null || positionData.isBlank()) {
            positionData = "{}";
        }
        if (progressPercentage == null) {
            progressPercentage = BigDecimal.ZERO;
        }
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public BookFile getBookFile() {
        return bookFile;
    }

    public void setBookFile(BookFile bookFile) {
        this.bookFile = bookFile;
    }

    public String getFormat() {
        return format;
    }

    public void setFormat(String format) {
        this.format = format;
    }

    public Integer getCurrentPage() {
        return currentPage;
    }

    public void setCurrentPage(Integer currentPage) {
        this.currentPage = currentPage;
    }

    public Integer getTotalPages() {
        return totalPages;
    }

    public void setTotalPages(Integer totalPages) {
        this.totalPages = totalPages;
    }

    public String getChapterHref() {
        return chapterHref;
    }

    public void setChapterHref(String chapterHref) {
        this.chapterHref = chapterHref;
    }

    public String getEpubCfi() {
        return epubCfi;
    }

    public void setEpubCfi(String epubCfi) {
        this.epubCfi = epubCfi;
    }

    public Long getAudioPositionMs() {
        return audioPositionMs;
    }

    public void setAudioPositionMs(Long audioPositionMs) {
        this.audioPositionMs = audioPositionMs;
    }

    public Long getAudioDurationMs() {
        return audioDurationMs;
    }

    public void setAudioDurationMs(Long audioDurationMs) {
        this.audioDurationMs = audioDurationMs;
    }

    public BigDecimal getProgressPercentage() {
        return progressPercentage;
    }

    public void setProgressPercentage(BigDecimal progressPercentage) {
        this.progressPercentage = progressPercentage;
    }

    public String getPositionData() {
        return positionData;
    }

    public void setPositionData(String positionData) {
        this.positionData = positionData;
    }

    public OffsetDateTime getLastOpenedAt() {
        return lastOpenedAt;
    }

    public void setLastOpenedAt(OffsetDateTime lastOpenedAt) {
        this.lastOpenedAt = lastOpenedAt;
    }

    public OffsetDateTime getClientUpdatedAt() {
        return clientUpdatedAt;
    }

    public void setClientUpdatedAt(OffsetDateTime clientUpdatedAt) {
        this.clientUpdatedAt = clientUpdatedAt;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
