package com.readingsanctuary.api.tts.repository;

import java.util.Optional;
import java.util.UUID;

import com.readingsanctuary.api.tts.entity.TtsPlaybackPosition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TtsPlaybackPositionRepository extends JpaRepository<TtsPlaybackPosition, UUID> {

    Optional<TtsPlaybackPosition> findByBook_IdAndBookFile_Id(UUID bookId, UUID bookFileId);

    void deleteByBook_IdAndBookFile_Id(UUID bookId, UUID bookFileId);
}
