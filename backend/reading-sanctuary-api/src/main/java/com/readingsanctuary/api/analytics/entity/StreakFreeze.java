package com.readingsanctuary.api.analytics.entity;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

import com.readingsanctuary.api.user.entity.User;

import jakarta.persistence.*;

@Entity
@Table(name = "streak_freezes", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "freeze_date"})
})
public class StreakFreeze {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "freeze_date", nullable = false)
    private LocalDate freezeDate;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public StreakFreeze() {}

    public StreakFreeze(User user, LocalDate freezeDate) {
        this.user = user;
        this.freezeDate = freezeDate;
    }

    @PrePersist
    protected void onCreate() {
        this.createdAt = OffsetDateTime.now();
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

    public LocalDate getFreezeDate() {
        return freezeDate;
    }

    public void setFreezeDate(LocalDate freezeDate) {
        this.freezeDate = freezeDate;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }
}
