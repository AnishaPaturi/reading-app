package com.readingsanctuary.api.bookreview.service;

import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookreview.dto.BookReviewRequest;
import com.readingsanctuary.api.bookreview.dto.BookReviewResponse;
import com.readingsanctuary.api.bookreview.entity.BookReview;
import com.readingsanctuary.api.bookreview.repository.BookReviewRepository;

@Service
public class BookReviewService {

    private final BookRepository bookRepository;
    private final BookReviewRepository reviewRepository;

    public BookReviewService(
            BookRepository bookRepository,
            BookReviewRepository reviewRepository) {
        this.bookRepository = bookRepository;
        this.reviewRepository = reviewRepository;
    }

    @Transactional
    public BookReviewResponse save(
            UUID userId,
            UUID bookId,
            BookReviewRequest request) {

        Book book = getOwnedBook(bookId, userId);

        BookReview review = reviewRepository.findByBook_Id(bookId)
                .orElseGet(() -> {
                    BookReview newReview = new BookReview();
                    newReview.setBook(book);
                    return newReview;
                });

        review.setRating(request.rating());
        review.setReview(request.review());

        return toResponse(reviewRepository.save(review));
    }

    @Transactional(readOnly = true)
    public BookReviewResponse get(UUID userId, UUID bookId) {

        getOwnedBook(bookId, userId);

        BookReview review = reviewRepository.findByBook_Id(bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Review not found"));

        return toResponse(review);
    }

    @Transactional
    public void delete(UUID userId, UUID bookId) {

        getOwnedBook(bookId, userId);

        BookReview review = reviewRepository.findByBook_Id(bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Review not found"));

        reviewRepository.delete(review);
    }

    private Book getOwnedBook(UUID bookId, UUID userId) {

        return bookRepository.findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));
    }

    private BookReviewResponse toResponse(BookReview review) {

        return new BookReviewResponse(
                review.getId(),
                review.getBook().getId(),
                review.getRating(),
                review.getReview(),
                review.getCreatedAt(),
                review.getUpdatedAt()
        );
    }
}
