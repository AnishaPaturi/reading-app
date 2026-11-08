package com.readingsanctuary.api.readerposition.entity;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.common.enums.ReadingLocationType;

import jakarta.persistence.*;

@Entity
@Table(name = "book_reading_positions")
public class BookReadingPosition {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_file_id", nullable = false, unique = true)
    private BookFile bookFile;

    @Enumerated(EnumType.STRING)
    @Column(name = "location_type", nullable = false)
    private ReadingLocationType locationType;

    @Column(name = "location_value", nullable = false, columnDefinition = "TEXT")
    private String locationValue;

    @Column(name = "page_number")
    private Integer pageNumber;

    @Column(name = "total_pages")
    private Integer totalPages;

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
    public ReadingLocationType getLocationType() { return locationType; }
    public String getLocationValue() { return locationValue; }
    public Integer getPageNumber() { return pageNumber; }
    public Integer getTotalPages() { return totalPages; }
    public BigDecimal getProgressPercentage() { return progressPercentage; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    public void setBook(Book book) { this.book = book; }
    public void setBookFile(BookFile bookFile) { this.bookFile = bookFile; }
    public void setLocationType(ReadingLocationType locationType) { this.locationType = locationType; }
    public void setLocationValue(String locationValue) { this.locationValue = locationValue; }
    public void setPageNumber(Integer pageNumber) { this.pageNumber = pageNumber; }
    public void setTotalPages(Integer totalPages) { this.totalPages = totalPages; }
    public void setProgressPercentage(BigDecimal progressPercentage) { this.progressPercentage = progressPercentage; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
