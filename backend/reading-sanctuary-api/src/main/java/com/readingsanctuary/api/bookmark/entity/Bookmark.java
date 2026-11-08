package com.readingsanctuary.api.bookmark.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.common.enums.ReadingLocationType;

import jakarta.persistence.*;

@Entity
@Table(name = "bookmarks")
public class Bookmark {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_file_id", nullable = false)
    private BookFile bookFile;

    @Column(length = 150)
    private String label;

    @Column(columnDefinition = "TEXT")
    private String note;

    @Enumerated(EnumType.STRING)
    @Column(name = "location_type", nullable = false)
    private ReadingLocationType locationType;

    @Column(name = "location_value", nullable = false,
            columnDefinition = "TEXT")
    private String locationValue;

    @Column(name = "page_number")
    private Integer pageNumber;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        OffsetDateTime now = OffsetDateTime.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public Book getBook() { return book; }
    public BookFile getBookFile() { return bookFile; }
    public String getLabel() { return label; }
    public String getNote() { return note; }
    public ReadingLocationType getLocationType() { return locationType; }
    public String getLocationValue() { return locationValue; }
    public Integer getPageNumber() { return pageNumber; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    public void setBook(Book book) { this.book = book; }
    public void setBookFile(BookFile bookFile) { this.bookFile = bookFile; }
    public void setLabel(String label) { this.label = label; }
    public void setNote(String note) { this.note = note; }
    public void setLocationType(ReadingLocationType type) {
        this.locationType = type;
    }
    public void setLocationValue(String value) {
        this.locationValue = value;
    }
    public void setPageNumber(Integer pageNumber) {
        this.pageNumber = pageNumber;
    }
}
