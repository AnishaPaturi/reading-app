package com.readingsanctuary.api.readingprogress.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.readingprogress.entity.ReadingProgress;

@Repository
public interface ReadingProgressRepository extends JpaRepository<ReadingProgress, UUID> {

    Optional<ReadingProgress> findByUserIdAndBookFileId(
        UUID userId,
        UUID bookFileId
    );

    List<ReadingProgress> findAllByUserIdOrderByUpdatedAtDesc(
        UUID userId
    );

    void deleteByUserIdAndBookFileId(
        UUID userId,
        UUID bookFileId
    );
}
