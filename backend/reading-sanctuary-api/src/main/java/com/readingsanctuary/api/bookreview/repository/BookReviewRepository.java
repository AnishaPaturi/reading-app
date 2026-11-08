package com.readingsanctuary.api.bookreview.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.readingsanctuary.api.bookreview.entity.BookReview;

public interface BookReviewRepository
        extends JpaRepository<BookReview, UUID> {

    Optional<BookReview> findByBook_Id(UUID bookId);
}
