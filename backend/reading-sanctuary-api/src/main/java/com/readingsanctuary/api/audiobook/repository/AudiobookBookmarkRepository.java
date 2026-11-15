package com.readingsanctuary.api.audiobook.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.audiobook.entity.AudiobookBookmark;

@Repository
public interface AudiobookBookmarkRepository extends JpaRepository<AudiobookBookmark, UUID> {
    List<AudiobookBookmark> findByAudiobookIdAndUserIdOrderByCreatedAtDesc(UUID audiobookId, UUID userId);
    List<AudiobookBookmark> findByUserIdOrderByCreatedAtDesc(UUID userId);
    Optional<AudiobookBookmark> findByIdAndUserId(UUID id, UUID userId);
    void deleteByIdAndUserId(UUID id, UUID userId);
}
