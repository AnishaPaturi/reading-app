package com.readingsanctuary.api.audiobook.repository;

import java.util.Optional;
import java.util.UUID;

import com.readingsanctuary.api.audiobook.entity.AudiobookPlaybackPosition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AudiobookPlaybackPositionRepository extends JpaRepository<AudiobookPlaybackPosition, UUID> {

    Optional<AudiobookPlaybackPosition> findByBook_IdAndBookFile_Id(UUID bookId, UUID bookFileId);

    void deleteByBook_IdAndBookFile_Id(UUID bookId, UUID bookFileId);
}
