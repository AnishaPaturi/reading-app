package com.readingsanctuary.api.audiobook.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.audiobook.entity.AudioTrack;

@Repository
public interface AudioTrackRepository extends JpaRepository<AudioTrack, UUID> {
    List<AudioTrack> findByAudiobookIdOrderByTrackOrderAsc(UUID audiobookId);
}
