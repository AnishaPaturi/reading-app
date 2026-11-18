package com.readingsanctuary.api.bookshelf.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.user.entity.User;

import jakarta.persistence.*;

@Entity
@Table(name = "book_size_customizations", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "book_id"})
})
public class BookSizeCustomization {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;

    @Column(name = "height_factor", nullable = false)
    private Double heightFactor = 1.0;

    @Column(name = "preset_size", nullable = false, length = 10)
    private String presetSize = "M";

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public BookSizeCustomization() {}

    public BookSizeCustomization(User user, Book book, Double heightFactor, String presetSize) {
        this.user = user;
        this.book = book;
        this.heightFactor = heightFactor != null ? heightFactor : 1.0;
        this.presetSize = presetSize != null ? presetSize : "M";
    }

    @PrePersist
    protected void onCreate() {
        OffsetDateTime now = OffsetDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }

    public UUID getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Book getBook() {
        return book;
    }

    public void setBook(Book book) {
        this.book = book;
    }

    public Double getHeightFactor() {
        return heightFactor;
    }

    public void setHeightFactor(Double heightFactor) {
        this.heightFactor = heightFactor;
    }

    public String getPresetSize() {
        return presetSize;
    }

    public void setPresetSize(String presetSize) {
        this.presetSize = presetSize;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }
}
