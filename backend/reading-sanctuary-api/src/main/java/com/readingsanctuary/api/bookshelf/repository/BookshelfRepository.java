package com.readingsanctuary.api.bookshelf.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.readingsanctuary.api.bookshelf.entity.Bookshelf;

public interface BookshelfRepository
        extends JpaRepository<Bookshelf, UUID> {

    List<Bookshelf> findAllByUser_Id(UUID userId);

    Optional<Bookshelf> findByIdAndUser_Id(
            UUID shelfId, UUID userId);

    boolean existsByUser_IdAndNameIgnoreCase(
            UUID userId, String name);
}
