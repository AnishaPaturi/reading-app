package com.readingsanctuary.api.book.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.bookmetadata.author.entity.Author;
import com.readingsanctuary.api.bookmetadata.genre.entity.Genre;
import com.readingsanctuary.api.user.entity.User;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

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

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "reading_status", nullable = false, columnDefinition = "reading_status")
    private ReadingStatus readingStatus = ReadingStatus.TO_READ;

    @Column(name = "current_page", nullable = false)
    private Integer currentPage = 0;

    @Column(name = "total_pages")
    private Integer totalPages;

    @Column(name = "started_at")
    private LocalDate startedAt;

    @Column(name = "completed_at")
    private LocalDate completedAt;

    @Column(name = "last_read_at")
    private OffsetDateTime lastReadAt;

    @Column(name = "dnf_at")
    private OffsetDateTime dnfAt;

    @Column(name = "dnf_reason", length = 100)
    private String dnfReason;

    @Column(name = "dnf_notes", columnDefinition = "TEXT")
    private String dnfNotes;

    @Enumerated(EnumType.STRING)
    @Column(name = "previous_reading_status", length = 40)
    private ReadingStatus previousReadingStatus;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    @Column(name = "rating")
    private Double rating;

    @Column(name = "rating_out_of_100")
    private Integer ratingOutOf100;

    @Column(name = "spice_rating")
    private Integer spiceRating;

    @Column(name = "mood", length = 100)
    private String mood;

    @Column(name = "recommendation", length = 50)
    private String recommendation;

    @Column(name = "purchase_price", precision = 12, scale = 2)
    private BigDecimal purchasePrice;

    @Column(name = "currency", length = 10)
    private String currency = "INR";

    @Column(name = "acquisition_method", length = 50)
    private String acquisitionMethod;

    @Column(name = "purchase_date")
    private LocalDate purchaseDate;

    @Column(name = "tropes", columnDefinition = "TEXT")
    private String tropes;

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

    public ReadingStatus getReadingStatus() {
        return readingStatus;
    }

    public Integer getCurrentPage() {
        return currentPage;
    }

    public Integer getTotalPages() {
        return totalPages;
    }

    public LocalDate getStartedAt() {
        return startedAt;
    }

    public LocalDate getCompletedAt() {
        return completedAt;
    }

    public OffsetDateTime getLastReadAt() {
        return lastReadAt;
    }

    public void setReadingStatus(ReadingStatus readingStatus) {
        this.readingStatus = readingStatus;
    }

    public void setCurrentPage(Integer currentPage) {
        this.currentPage = currentPage;
    }

    public void setTotalPages(Integer totalPages) {
        this.totalPages = totalPages;
    }

    public void setStartedAt(LocalDate startedAt) {
        this.startedAt = startedAt;
    }

    public void setCompletedAt(LocalDate completedAt) {
        this.completedAt = completedAt;
    }

    public void setLastReadAt(OffsetDateTime lastReadAt) {
        this.lastReadAt = lastReadAt;
    }

    public OffsetDateTime getDnfAt() {
        return dnfAt;
    }

    public void setDnfAt(OffsetDateTime dnfAt) {
        this.dnfAt = dnfAt;
    }

    public String getDnfReason() {
        return dnfReason;
    }

    public void setDnfReason(String dnfReason) {
        this.dnfReason = dnfReason;
    }

    public String getDnfNotes() {
        return dnfNotes;
    }

    public void setDnfNotes(String dnfNotes) {
        this.dnfNotes = dnfNotes;
    }

    public ReadingStatus getPreviousReadingStatus() {
        return previousReadingStatus;
    }

    public void setPreviousReadingStatus(ReadingStatus previousReadingStatus) {
        this.previousReadingStatus = previousReadingStatus;
    }

    public OffsetDateTime getDeletedAt() {
        return deletedAt;
    }

    public void setDeletedAt(OffsetDateTime deletedAt) {
        this.deletedAt = deletedAt;
    }

    public Double getRating() {
        return rating;
    }

    public void setRating(Double rating) {
        this.rating = rating;
    }

    public Integer getRatingOutOf100() {
        return ratingOutOf100;
    }

    public void setRatingOutOf100(Integer ratingOutOf100) {
        this.ratingOutOf100 = ratingOutOf100;
    }

    public Integer getSpiceRating() {
        return spiceRating;
    }

    public void setSpiceRating(Integer spiceRating) {
        this.spiceRating = spiceRating;
    }

    public String getMood() {
        return mood;
    }

    public void setMood(String mood) {
        this.mood = mood;
    }

    public String getRecommendation() {
        return recommendation;
    }

    public void setRecommendation(String recommendation) {
        this.recommendation = recommendation;
    }

    public BigDecimal getPurchasePrice() {
        return purchasePrice;
    }

    public void setPurchasePrice(BigDecimal purchasePrice) {
        this.purchasePrice = purchasePrice;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getAcquisitionMethod() {
        return acquisitionMethod;
    }

    public void setAcquisitionMethod(String acquisitionMethod) {
        this.acquisitionMethod = acquisitionMethod;
    }

    public LocalDate getPurchaseDate() {
        return purchaseDate;
    }

    public void setPurchaseDate(LocalDate purchaseDate) {
        this.purchaseDate = purchaseDate;
    }

    public String getTropes() {
        return tropes;
    }

    public void setTropes(String tropes) {
        this.tropes = tropes;
    }
}
