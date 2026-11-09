package com.readingsanctuary.api.analytics.repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.readingsanctuary.api.analytics.entity.ReadingActivitySession;
import com.readingsanctuary.api.analytics.enums.ActivityType;

public interface ReadingActivitySessionRepository extends JpaRepository<ReadingActivitySession, UUID> {

    Optional<ReadingActivitySession> findByIdAndUser_Id(UUID id, UUID userId);

    List<ReadingActivitySession> findByUser_IdAndIsActiveTrue(UUID userId);

    List<ReadingActivitySession> findAllByUser_IdOrderByStartedAtDesc(UUID userId);

    List<ReadingActivitySession> findAllByUser_IdAndStartedAtBetweenOrderByStartedAtAsc(
            UUID userId, OffsetDateTime start, OffsetDateTime end);

    @Query("SELECT s.activityType, COALESCE(SUM(s.durationSeconds), 0) " +
           "FROM ReadingActivitySession s " +
           "WHERE s.user.id = :userId AND s.startedAt >= :start AND s.startedAt <= :end " +
           "GROUP BY s.activityType")
    List<Object[]> sumDurationByActivityType(
            @Param("userId") UUID userId,
            @Param("start") OffsetDateTime start,
            @Param("end") OffsetDateTime end);

    @Query("SELECT COALESCE(SUM(s.pagesAdvanced), 0) " +
           "FROM ReadingActivitySession s " +
           "WHERE s.user.id = :userId AND s.startedAt >= :start AND s.startedAt <= :end")
    int sumPagesAdvanced(
            @Param("userId") UUID userId,
            @Param("start") OffsetDateTime start,
            @Param("end") OffsetDateTime end);

    @Query("SELECT s.activityType, COUNT(s) " +
           "FROM ReadingActivitySession s " +
           "WHERE s.user.id = :userId AND s.startedAt >= :start AND s.startedAt <= :end " +
           "GROUP BY s.activityType")
    List<Object[]> countSessionsByActivityType(
            @Param("userId") UUID userId,
            @Param("start") OffsetDateTime start,
            @Param("end") OffsetDateTime end);

    @Query("SELECT s FROM ReadingActivitySession s " +
           "WHERE s.isActive = true AND s.lastHeartbeatAt < :threshold")
    List<ReadingActivitySession> findStaleActiveSessions(@Param("threshold") OffsetDateTime threshold);
}
