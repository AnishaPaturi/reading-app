package com.readingsanctuary.api.bookhistory.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import com.readingsanctuary.api.bookhistory.entity.BookReadingHistory;

public interface BookReadingHistoryRepository
        extends JpaRepository<BookReadingHistory, UUID> {

    List<BookReadingHistory> findAllByBook_IdOrderByChangedAtDesc(UUID bookId);
}
