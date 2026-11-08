package com.readingsanctuary.api.note.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.readingsanctuary.api.note.entity.BookNote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookNoteRepository
        extends JpaRepository<BookNote, UUID> {

    List<BookNote> findAllByBook_IdOrderByUpdatedAtDesc(UUID bookId);

    Optional<BookNote> findByIdAndBook_Id(
            UUID noteId, UUID bookId);
}
