package com.readingsanctuary.api.sync.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.sync.entity.SyncChange;

@Repository
public interface SyncChangeRepository extends JpaRepository<SyncChange, Long> {

    List<SyncChange> findByUserIdAndCursorGreaterThanOrderByCursorAsc(
            UUID userId,
            long cursor,
            Pageable pageable
    );

    long countByUserIdAndCursorGreaterThan(UUID userId, long cursor);

    @Query("SELECT MAX(c.cursor) FROM SyncChange c WHERE c.userId = :userId")
    Optional<Long> findMaxCursorByUserId(@Param("userId") UUID userId);

    @Query("SELECT c FROM SyncChange c WHERE c.userId = :userId AND c.entityType = :entityType AND c.entityId = :entityId ORDER BY c.cursor DESC")
    List<SyncChange> findLatestChange(
            @Param("userId") UUID userId,
            @Param("entityType") String entityType,
            @Param("entityId") String entityId,
            Pageable pageable
    );
}
