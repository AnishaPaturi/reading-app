package com.readingsanctuary.api.bookmark.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.readingsanctuary.api.bookmark.entity.Bookmark;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookmarkRepository
        extends JpaRepository<Bookmark, UUID> {

    List<Bookmark> findAllByBook_IdOrderByCreatedAtDesc(UUID bookId);

    Optional<Bookmark> findByIdAndBook_Id(
            UUID bookmarkId, UUID bookId);
}
