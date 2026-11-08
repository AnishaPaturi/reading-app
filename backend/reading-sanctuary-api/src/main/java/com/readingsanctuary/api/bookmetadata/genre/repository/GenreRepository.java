package com.readingsanctuary.api.bookmetadata.genre.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.readingsanctuary.api.bookmetadata.genre.entity.Genre;

public interface GenreRepository extends JpaRepository<Genre, UUID> {

    Optional<Genre> findByNameIgnoreCase(String name);
}
