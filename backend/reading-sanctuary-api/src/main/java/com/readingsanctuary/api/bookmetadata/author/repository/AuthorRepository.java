package com.readingsanctuary.api.bookmetadata.author.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.readingsanctuary.api.bookmetadata.author.entity.Author;

public interface AuthorRepository extends JpaRepository<Author, UUID> {

    Optional<Author> findByNameIgnoreCase(String name);
}
