package com.readingsanctuary.api.readerposition.repository;

import java.util.Optional;
import java.util.UUID;

import com.readingsanctuary.api.readerposition.entity.BookReadingPosition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookReadingPositionRepository extends JpaRepository<BookReadingPosition, UUID> {

    Optional<BookReadingPosition> findByBook_IdAndBookFile_Id(UUID bookId, UUID bookFileId);

    void deleteByBook_IdAndBookFile_Id(UUID bookId, UUID bookFileId);
}
