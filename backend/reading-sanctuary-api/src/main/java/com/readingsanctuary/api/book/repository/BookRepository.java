package com.readingsanctuary.api.book.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.enums.ReadingStatus;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookRepository extends JpaRepository<Book, UUID> {
    List<Book> findAllByCreatedBy_Id(UUID userId);

    Optional<Book> findByIdAndCreatedBy_Id(
        UUID bookId,
        UUID userId
    );

    List<Book> findAllByCreatedBy_IdAndReadingStatus(
        UUID userId,
        ReadingStatus readingStatus
    );

    long countByCreatedBy_Id(UUID userId);

    long countByCreatedBy_IdAndReadingStatus(UUID userId, ReadingStatus readingStatus);

    @org.springframework.data.jpa.repository.Query("SELECT COUNT(DISTINCT b) FROM Book b " +
           "WHERE b.createdBy.id = :userId " +
           "AND b.readingStatus = com.readingsanctuary.api.book.enums.ReadingStatus.COMPLETED " +
           "AND (:start IS NULL OR b.completedAt >= :start) " +
           "AND (:end IS NULL OR b.completedAt <= :end)")
    long countCompletedBooksBetween(
            @org.springframework.data.repository.query.Param("userId") UUID userId,
            @org.springframework.data.repository.query.Param("start") java.time.LocalDate start,
            @org.springframework.data.repository.query.Param("end") java.time.LocalDate end);

    @org.springframework.data.jpa.repository.Query("SELECT b FROM Book b " +
           "WHERE b.createdBy.id = :userId " +
           "AND b.readingStatus = com.readingsanctuary.api.book.enums.ReadingStatus.COMPLETED " +
           "AND (:start IS NULL OR b.completedAt >= :start) " +
           "AND (:end IS NULL OR b.completedAt <= :end)")
    List<Book> findCompletedBooksBetween(
            @org.springframework.data.repository.query.Param("userId") UUID userId,
            @org.springframework.data.repository.query.Param("start") java.time.LocalDate start,
            @org.springframework.data.repository.query.Param("end") java.time.LocalDate end);

    @org.springframework.data.jpa.repository.Query("SELECT g.name, COUNT(DISTINCT b.id) " +
           "FROM Book b JOIN b.genres g " +
           "WHERE b.createdBy.id = :userId " +
           "AND b.readingStatus = com.readingsanctuary.api.book.enums.ReadingStatus.COMPLETED " +
           "AND (:start IS NULL OR b.completedAt >= :start) " +
           "AND (:end IS NULL OR b.completedAt <= :end) " +
           "GROUP BY g.name " +
           "ORDER BY COUNT(DISTINCT b.id) DESC")
    List<Object[]> countCompletedBooksByGenre(
            @org.springframework.data.repository.query.Param("userId") UUID userId,
            @org.springframework.data.repository.query.Param("start") java.time.LocalDate start,
            @org.springframework.data.repository.query.Param("end") java.time.LocalDate end);

    @org.springframework.data.jpa.repository.Query("SELECT a.name, COUNT(DISTINCT b.id) " +
           "FROM Book b JOIN b.authors a " +
           "WHERE b.createdBy.id = :userId " +
           "AND b.readingStatus = com.readingsanctuary.api.book.enums.ReadingStatus.COMPLETED " +
           "AND (:start IS NULL OR b.completedAt >= :start) " +
           "AND (:end IS NULL OR b.completedAt <= :end) " +
           "GROUP BY a.name " +
           "ORDER BY COUNT(DISTINCT b.id) DESC")
    List<Object[]> countCompletedBooksByAuthor(
            @org.springframework.data.repository.query.Param("userId") UUID userId,
            @org.springframework.data.repository.query.Param("start") java.time.LocalDate start,
            @org.springframework.data.repository.query.Param("end") java.time.LocalDate end);
}
