package com.readingsanctuary.api.analytics.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.analytics.entity.StreakFreeze;

@Repository
public interface StreakFreezeRepository extends JpaRepository<StreakFreeze, UUID> {

    List<StreakFreeze> findAllByUser_IdOrderByFreezeDateDesc(UUID userId);

    Optional<StreakFreeze> findByUser_IdAndFreezeDate(UUID userId, LocalDate freezeDate);

    long countByUser_Id(UUID userId);
}
