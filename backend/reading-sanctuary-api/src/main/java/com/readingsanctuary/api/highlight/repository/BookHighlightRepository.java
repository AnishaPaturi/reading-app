package com.readingsanctuary.api.highlight.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.readingsanctuary.api.highlight.entity.BookHighlight;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookHighlightRepository
        extends JpaRepository<BookHighlight, UUID> {

    List<BookHighlight> findAllByBook_IdOrderByCreatedAtDesc(UUID bookId);

    Optional<BookHighlight> findByIdAndBook_Id(
            UUID highlightId, UUID bookId);
}
