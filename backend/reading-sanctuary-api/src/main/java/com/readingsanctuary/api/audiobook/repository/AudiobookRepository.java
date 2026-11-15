package com.readingsanctuary.api.audiobook.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.audiobook.entity.Audiobook;

@Repository
public interface AudiobookRepository extends JpaRepository<Audiobook, UUID> {
    List<Audiobook> findByUserIdOrderByCreatedAtDesc(UUID userId);
    Optional<Audiobook> findByIdAndUserId(UUID id, UUID userId);
    void deleteByIdAndUserId(UUID id, UUID userId);
}
