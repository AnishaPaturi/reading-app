package com.readingsanctuary.api.bookshelf.entity;

import java.time.OffsetDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.user.entity.User;
import jakarta.persistence.*;

@Entity
@Table(name = "bookshelves")
public class Bookshelf {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(length = 20)
    private String color;

    @Column(name = "theme_color", length = 30)
    private String themeColor;

    @Column(name = "accent_color", length = 30)
    private String accentColor;

    @Column(length = 100)
    private String icon;

    @Column(name = "background_style", length = 50)
    private String backgroundStyle = "solid";

    @Column(name = "layout_style", length = 50)
    private String layoutStyle = "shelf";

    @Column(name = "is_favorite", nullable = false)
    private boolean isFavorite = false;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder = 0;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "bookshelf_books",
        joinColumns = @JoinColumn(name = "bookshelf_id"),
        inverseJoinColumns = @JoinColumn(name = "book_id")
    )
    private Set<Book> books = new HashSet<>();

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public User getUser() { return user; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public String getColor() { return color; }
    public String getThemeColor() { return themeColor; }
    public String getAccentColor() { return accentColor; }
    public String getIcon() { return icon; }
    public String getBackgroundStyle() { return backgroundStyle; }
    public String getLayoutStyle() { return layoutStyle; }
    public boolean isFavorite() { return isFavorite; }
    public int getSortOrder() { return sortOrder; }
    public Set<Book> getBooks() { return books; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    public void setUser(User user) { this.user = user; }
    public void setName(String name) { this.name = name; }
    public void setDescription(String description) { this.description = description; }
    public void setColor(String color) { this.color = color; }
    public void setThemeColor(String themeColor) { this.themeColor = themeColor; }
    public void setAccentColor(String accentColor) { this.accentColor = accentColor; }
    public void setIcon(String icon) { this.icon = icon; }
    public void setBackgroundStyle(String backgroundStyle) { this.backgroundStyle = backgroundStyle; }
    public void setLayoutStyle(String layoutStyle) { this.layoutStyle = layoutStyle; }
    public void setFavorite(boolean favorite) { isFavorite = favorite; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }
    public void setBooks(Set<Book> books) { this.books = books; }
}
