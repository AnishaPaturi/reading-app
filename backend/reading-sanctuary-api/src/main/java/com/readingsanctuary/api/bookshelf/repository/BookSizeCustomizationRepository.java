package com.readingsanctuary.api.bookshelf.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.bookshelf.entity.BookSizeCustomization;

@Repository
public interface BookSizeCustomizationRepository extends JpaRepository<BookSizeCustomization, UUID> {

    List<BookSizeCustomization> findAllByUser_Id(UUID userId);

    Optional<BookSizeCustomization> findByUser_IdAndBook_Id(UUID userId, UUID bookId);

    void deleteByUser_IdAndBook_Id(UUID userId, UUID bookId);

    void deleteAllByUser_Id(UUID userId);
}
