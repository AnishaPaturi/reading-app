package com.readingsanctuary.api.audiobook.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.audiobook.entity.AudiobookListeningSession;

@Repository
public interface AudiobookListeningSessionRepository extends JpaRepository<AudiobookListeningSession, UUID> {
    List<AudiobookListeningSession> findByUserIdOrderByStartedAtDesc(UUID userId);
    List<AudiobookListeningSession> findByAudiobookIdAndUserIdOrderByStartedAtDesc(UUID audiobookId, UUID userId);
}
