package com.readingsanctuary.api.bookreading.service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookhistory.entity.BookReadingHistory;
import com.readingsanctuary.api.bookhistory.repository.BookReadingHistoryRepository;
import com.readingsanctuary.api.bookreading.dto.ReadingHistoryResponse;
import com.readingsanctuary.api.bookreading.dto.ReadingResponse;
import com.readingsanctuary.api.bookreading.dto.UpdateReadingRequest;

@Service
public class BookReadingService {

    private final BookRepository bookRepository;
    private final BookReadingHistoryRepository historyRepository;

    public BookReadingService(
            BookRepository bookRepository,
            BookReadingHistoryRepository historyRepository) {

        this.bookRepository = bookRepository;
        this.historyRepository = historyRepository;
    }

    @Transactional
    public ReadingResponse updateReading(
            UUID userId,
            UUID bookId,
            UpdateReadingRequest request) {

        Book book = getOwnedBook(bookId, userId);

        ReadingStatus previousStatus = book.getReadingStatus();

        Integer newCurrentPage = request.currentPage() != null
                ? request.currentPage()
                : book.getCurrentPage();

        Integer newTotalPages = request.totalPages() != null
                ? request.totalPages()
                : book.getTotalPages();

        if (newCurrentPage == null || newCurrentPage < 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Current page cannot be negative");
        }

        if (newTotalPages != null) {
            if (newTotalPages <= 0) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Total pages must be positive");
            }

            if (newCurrentPage > newTotalPages) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Current page cannot exceed total pages");
            }
        }

        ReadingStatus newStatus = request.status() != null
                ? request.status()
                : previousStatus;

        if (newStatus == ReadingStatus.COMPLETED) {
            if (newTotalPages != null) {
                newCurrentPage = newTotalPages;
            }
        }

        if (newStatus == ReadingStatus.COMPLETED
                && newTotalPages != null
                && newCurrentPage < newTotalPages) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Complete the final page before marking the book completed");
        }

        LocalDate today = LocalDate.now();

        if (request.startedAt() != null) {
            book.setStartedAt(request.startedAt());
        } else if (newStatus == ReadingStatus.CURRENTLY_READING
                && book.getStartedAt() == null) {
            book.setStartedAt(today);
        }

        if (newStatus == ReadingStatus.COMPLETED) {
            if (request.completedAt() != null) {
                book.setCompletedAt(request.completedAt());
            } else if (previousStatus != ReadingStatus.COMPLETED
                    || book.getCompletedAt() == null) {
                book.setCompletedAt(today);
            }
        } else if (request.completedAt() != null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Completion date is only valid for completed books");
        } else if (previousStatus == ReadingStatus.COMPLETED) {
            book.setCompletedAt(null);
        }

        if (book.getStartedAt() != null
                && book.getCompletedAt() != null
                && book.getCompletedAt().isBefore(book.getStartedAt())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Completion date cannot be before start date");
        }

        book.setReadingStatus(newStatus);
        book.setCurrentPage(newCurrentPage);
        book.setTotalPages(newTotalPages);

        if (request.currentPage() != null
                || request.status() != null) {
            book.setLastReadAt(OffsetDateTime.now());
        }

        if (previousStatus != newStatus) {
            BookReadingHistory history = new BookReadingHistory();
            history.setBook(book);
            history.setPreviousStatus(
                    previousStatus == null ? null : previousStatus.name());
            history.setNewStatus(newStatus.name());
            history.setCurrentPage(newCurrentPage);

            historyRepository.save(history);
        }

        bookRepository.save(book);

        return toResponse(book);
    }

    @Transactional(readOnly = true)
    public ReadingResponse getReading(UUID userId, UUID bookId) {
        return toResponse(getOwnedBook(bookId, userId));
    }

    @Transactional(readOnly = true)
    public List<ReadingResponse> getBooksByStatus(
            UUID userId,
            ReadingStatus status) {

        return bookRepository
                .findAllByCreatedBy_IdAndReadingStatus(userId, status)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ReadingHistoryResponse> getReadingHistory(
            UUID userId,
            UUID bookId) {

        getOwnedBook(bookId, userId);

        return historyRepository
                .findAllByBook_IdOrderByChangedAtDesc(bookId)
                .stream()
                .map(history -> new ReadingHistoryResponse(
                        history.getId(),
                        history.getPreviousStatus(),
                        history.getNewStatus(),
                        history.getCurrentPage(),
                        history.getChangedAt()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ReadingHistoryResponse> getHistory(
            UUID userId,
            UUID bookId) {
        return getReadingHistory(userId, bookId);
    }

    private Book getOwnedBook(UUID bookId, UUID userId) {
        return bookRepository.findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));
    }

    private ReadingResponse toResponse(Book book) {
        Double percentage = null;
        if (book.getTotalPages() != null && book.getTotalPages() > 0) {
            percentage = Math.round(
                    (book.getCurrentPage() * 10000.0)
                            / book.getTotalPages()) / 100.0;
        }

        return new ReadingResponse(
                book.getId(),
                book.getTitle(),
                book.getReadingStatus(),
                book.getCurrentPage(),
                book.getTotalPages(),
                percentage,
                book.getStartedAt(),
                book.getCompletedAt(),
                book.getLastReadAt()
        );
    }
}
