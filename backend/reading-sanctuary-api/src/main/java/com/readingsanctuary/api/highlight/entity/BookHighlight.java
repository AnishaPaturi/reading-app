package com.readingsanctuary.api.highlight.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.common.enums.HighlightColor;
import com.readingsanctuary.api.common.enums.ReadingLocationType;

import jakarta.persistence.*;

@Entity
@Table(name = "book_highlights")
public class BookHighlight {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_file_id", nullable = false)
    private BookFile bookFile;

    @Column(name = "selected_text", nullable = false,
            columnDefinition = "TEXT")
    private String selectedText;

    @Enumerated(EnumType.STRING)
    @Column(name = "location_type", nullable = false)
    private ReadingLocationType locationType;

    @Column(name = "start_location", nullable = false,
            columnDefinition = "TEXT")
    private String startLocation;

    @Column(name = "end_location", nullable = false,
            columnDefinition = "TEXT")
    private String endLocation;

    @Column(name = "page_number")
    private Integer pageNumber;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private HighlightColor color = HighlightColor.YELLOW;

    @Column(name = "annotation_note", columnDefinition = "TEXT")
    private String annotationNote;

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
    public String getSelectedText() { return selectedText; }
    public ReadingLocationType getLocationType() { return locationType; }
    public String getStartLocation() { return startLocation; }
    public String getEndLocation() { return endLocation; }
    public Integer getPageNumber() { return pageNumber; }
    public HighlightColor getColor() { return color; }
    public String getAnnotationNote() { return annotationNote; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    public void setBook(Book book) { this.book = book; }
    public void setBookFile(BookFile bookFile) { this.bookFile = bookFile; }
    public void setSelectedText(String text) { this.selectedText = text; }
    public void setLocationType(ReadingLocationType type) {
        this.locationType = type;
    }
    public void setStartLocation(String value) {
        this.startLocation = value;
    }
    public void setEndLocation(String value) {
        this.endLocation = value;
    }
    public void setPageNumber(Integer pageNumber) {
        this.pageNumber = pageNumber;
    }
    public void setColor(HighlightColor color) { this.color = color; }
    public void setAnnotationNote(String note) {
        this.annotationNote = note;
    }
}
