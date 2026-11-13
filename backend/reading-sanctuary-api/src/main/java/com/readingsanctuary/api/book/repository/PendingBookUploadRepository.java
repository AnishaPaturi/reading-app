package com.readingsanctuary.api.book.repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.book.entity.PendingBookUpload;

@Repository
public interface PendingBookUploadRepository extends JpaRepository<PendingBookUpload, UUID> {

    Optional<PendingBookUpload> findByIdAndUser_Id(UUID id, UUID userId);

    List<PendingBookUpload> findAllByUser_Id(UUID userId);

    List<PendingBookUpload> findAllByExpiresAtBefore(OffsetDateTime cutoff);
}
