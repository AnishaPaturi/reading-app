package com.readingsanctuary.api.sync.repository;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.sync.entity.SyncProcessedChange;

@Repository
public interface SyncProcessedChangeRepository extends JpaRepository<SyncProcessedChange, String> {

    boolean existsByClientChangeIdAndUserId(String clientChangeId, UUID userId);
}
