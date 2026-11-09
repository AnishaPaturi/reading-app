package com.readingsanctuary.api.analytics.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.readingsanctuary.api.analytics.entity.ReadingGoal;
import com.readingsanctuary.api.analytics.enums.GoalPeriod;
import com.readingsanctuary.api.analytics.enums.GoalType;

public interface ReadingGoalRepository extends JpaRepository<ReadingGoal, UUID> {

    Optional<ReadingGoal> findByIdAndUser_Id(UUID id, UUID userId);

    List<ReadingGoal> findAllByUser_IdOrderByCreatedAtDesc(UUID userId);

    List<ReadingGoal> findAllByUser_IdAndIsActiveTrue(UUID userId);

    @Query("SELECT g FROM ReadingGoal g " +
           "WHERE g.user.id = :userId AND g.isActive = true " +
           "AND g.goalType = :goalType AND g.periodType = :periodType " +
           "AND (:id IS NULL OR g.id != :id) " +
           "AND ((:endDate IS NULL OR g.startDate <= :endDate) AND (g.endDate IS NULL OR g.endDate >= :startDate))")
    List<ReadingGoal> findOverlappingActiveGoals(
            @Param("userId") UUID userId,
            @Param("goalType") GoalType goalType,
            @Param("periodType") GoalPeriod periodType,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            @Param("id") UUID id);
}
