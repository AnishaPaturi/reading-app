package com.readingsanctuary.api.bookfile.repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.bookfile.entity.BookFile;

@Repository
public interface BookFileRepository extends JpaRepository<BookFile, UUID> {

    List<BookFile> findAllByBook_Id(UUID bookId);

    Optional<BookFile> findByIdAndBook_Id(UUID fileId, UUID bookId);

    boolean existsByBook_CreatedBy_IdAndChecksum(UUID userId, String checksum);

    Optional<BookFile> findFirstByBook_CreatedBy_IdAndChecksum(UUID userId, String checksum);

    @Query("SELECT bf FROM BookFile bf JOIN FETCH bf.book WHERE bf.book.createdBy.id = :userId AND bf.checksum = :checksum")
    Optional<BookFile> findByUserIdAndChecksumWithBook(@Param("userId") UUID userId, @Param("checksum") String checksum);

    @Query("SELECT bf FROM BookFile bf JOIN FETCH bf.book WHERE bf.book.createdBy.id = :userId AND bf.checksum IN :checksums")
    List<BookFile> findAllByUserIdAndChecksumsInWithBook(
            @Param("userId") UUID userId,
            @Param("checksums") Collection<String> checksums
    );
}
