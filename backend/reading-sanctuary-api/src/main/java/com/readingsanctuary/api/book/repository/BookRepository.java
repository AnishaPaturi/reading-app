package com.readingsanctuary.api.book.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookRepository extends JpaRepository<Book, UUID> {
    List<Book> findAllByCreatedBy_Id(UUID userId);

    Optional<Book> findByIdAndCreatedBy_Id(
        UUID bookId,
        UUID userId
    );
}
