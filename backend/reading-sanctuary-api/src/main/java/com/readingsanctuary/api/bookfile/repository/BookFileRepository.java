package com.readingsanctuary.api.bookfile.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.bookfile.entity.BookFile;

@Repository
public interface BookFileRepository extends JpaRepository<BookFile, UUID> {

    List<BookFile> findAllByBook_Id(UUID bookId);

    Optional<BookFile> findByIdAndBook_Id(UUID fileId, UUID bookId);
}
