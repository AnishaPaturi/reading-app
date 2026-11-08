package com.readingsanctuary.api.bookhistory.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;

import jakarta.persistence.*;

@Entity
@Table(name = "book_reading_history")
public class BookReadingHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @Column(name = "previous_status", length = 30)
    private String previousStatus;

    @Column(name = "new_status", nullable = false, length = 30)
    private String newStatus;

    @Column(name = "current_page", nullable = false)
    private Integer currentPage;

    @Column(name = "changed_at", nullable = false)
    private OffsetDateTime changedAt;

    @PrePersist
    protected void onCreate() {
        changedAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public Book getBook() { return book; }
    public String getPreviousStatus() { return previousStatus; }
    public String getNewStatus() { return newStatus; }
    public Integer getCurrentPage() { return currentPage; }
    public OffsetDateTime getChangedAt() { return changedAt; }

    public void setBook(Book book) { this.book = book; }
    public void setPreviousStatus(String previousStatus) {
        this.previousStatus = previousStatus;
    }
    public void setNewStatus(String newStatus) {
        this.newStatus = newStatus;
    }
    public void setCurrentPage(Integer currentPage) {
        this.currentPage = currentPage;
    }
}
