package com.readingsanctuary.api.audiobook.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.audiobook.entity.AudiobookProgress;

@Repository
public interface AudiobookProgressRepository extends JpaRepository<AudiobookProgress, UUID> {
    Optional<AudiobookProgress> findByAudiobookIdAndUserId(UUID audiobookId, UUID userId);
}
