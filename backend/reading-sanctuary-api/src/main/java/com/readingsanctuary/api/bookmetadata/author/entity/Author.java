package com.readingsanctuary.api.bookmetadata.author.entity;

import java.time.OffsetDateTime;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(name = "authors")
public class Author {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 255)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String biography;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }

    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getBiography() { return biography; }
    public OffsetDateTime getCreatedAt() { return createdAt; }

    public void setName(String name) { this.name = name; }
    public void setBiography(String biography) { this.biography = biography; }
}
