package com.readingsanctuary.api.book.entity;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import com.readingsanctuary.api.bookmetadata.author.entity.Author;
import com.readingsanctuary.api.bookmetadata.genre.entity.Genre;
import com.readingsanctuary.api.user.entity.User;

import jakarta.persistence.*;

@Entity
@Table(name = "books")
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "created_by", nullable = false)
    private User createdBy;

    @Column(nullable = false, length = 500)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(length = 50)
    private String language;

    @Column(length = 255)
    private String publisher;

    @Column(name = "publication_date")
    private LocalDate publicationDate;

    @Column(length = 20)
    private String isbn;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @ManyToMany
    @JoinTable(
        name = "book_authors",
        joinColumns = @JoinColumn(name = "book_id"),
        inverseJoinColumns = @JoinColumn(name = "author_id")
    )
    private Set<Author> authors = new HashSet<>();

    @ManyToMany
    @JoinTable(
        name = "book_genres",
        joinColumns = @JoinColumn(name = "book_id"),
        inverseJoinColumns = @JoinColumn(name = "genre_id")
    )
    private Set<Genre> genres = new HashSet<>();

    @Column(name = "cover_storage_key", length = 500)
    private String coverStorageKey;

    @Column(name = "cover_file_name", length = 255)
    private String coverFileName;

    @Column(name = "cover_content_type", length = 100)
    private String coverContentType;

    @Column(name = "cover_updated_at")
    private OffsetDateTime coverUpdatedAt;

    // Required by JPA
    public Book() {
    }

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

    // Getters and setters

    public UUID getId() {
        return id;
    }

    public User getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(User createdBy) {
        this.createdBy = createdBy;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public String getPublisher() {
        return publisher;
    }

    public void setPublisher(String publisher) {
        this.publisher = publisher;
    }

    public LocalDate getPublicationDate() {
        return publicationDate;
    }

    public void setPublicationDate(LocalDate publicationDate) {
        this.publicationDate = publicationDate;
    }

    public String getIsbn() {
        return isbn;
    }

    public void setIsbn(String isbn) {
        this.isbn = isbn;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public Set<Author> getAuthors() {
        return authors;
    }

    public Set<Genre> getGenres() {
        return genres;
    }

    public String getCoverStorageKey() {
        return coverStorageKey;
    }

    public String getCoverFileName() {
        return coverFileName;
    }

    public String getCoverContentType() {
        return coverContentType;
    }

    public OffsetDateTime getCoverUpdatedAt() {
        return coverUpdatedAt;
    }

    public void setAuthors(Set<Author> authors) {
        this.authors = authors;
    }

    public void setGenres(Set<Genre> genres) {
        this.genres = genres;
    }

    public void setCoverStorageKey(String coverStorageKey) {
        this.coverStorageKey = coverStorageKey;
    }

    public void setCoverFileName(String coverFileName) {
        this.coverFileName = coverFileName;
    }

    public void setCoverContentType(String coverContentType) {
        this.coverContentType = coverContentType;
    }

    public void setCoverUpdatedAt(OffsetDateTime coverUpdatedAt) {
        this.coverUpdatedAt = coverUpdatedAt;
    }
}
