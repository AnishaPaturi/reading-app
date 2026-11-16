package com.readingsanctuary.api.annotation.service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.annotation.dto.AnnotationResponse;
import com.readingsanctuary.api.annotation.dto.CreateAnnotationRequest;
import com.readingsanctuary.api.annotation.dto.UpdateAnnotationRequest;
import com.readingsanctuary.api.annotation.entity.Annotation;
import com.readingsanctuary.api.annotation.entity.AnnotationType;
import com.readingsanctuary.api.annotation.repository.AnnotationRepository;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
@Transactional
public class AnnotationService {

    private final AnnotationRepository annotationRepository;
    private final BookFileRepository bookFileRepository;
    private final UserRepository userRepository;

    public AnnotationService(
            AnnotationRepository annotationRepository,
            BookFileRepository bookFileRepository,
            UserRepository userRepository) {
        this.annotationRepository = annotationRepository;
        this.bookFileRepository = bookFileRepository;
        this.userRepository = userRepository;
    }

    public AnnotationResponse createAnnotation(UUID userId, CreateAnnotationRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));

        BookFile bookFile = bookFileRepository.findById(request.bookFileId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Book file not found"));

        Book book = bookFile.getBook();
        if (book == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Parent book not found for this file");
        }

        // Enforce ownership: the book must belong to the authenticated user
        if (!book.getCreatedBy().getId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not own this book");
        }

        if (request.bookId() != null && !book.getId().equals(request.bookId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "bookId does not match bookFile parent book");
        }

        Annotation annotation = new Annotation();
        annotation.setUser(user);
        annotation.setBook(book);
        annotation.setBookFile(bookFile);
        annotation.setType(AnnotationType.valueOf(request.type().toUpperCase()));
        annotation.setSelectedText(request.selectedText());
        annotation.setNoteText(request.noteText());
        annotation.setColor(request.color());
        annotation.setPageNumber(request.pageNumber());
        if (request.locationData() != null && !request.locationData().isBlank()) {
            annotation.setLocationData(request.locationData());
        }

        Annotation saved = annotationRepository.save(annotation);
        return AnnotationResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<AnnotationResponse> getAnnotationsByBookFile(UUID userId, UUID bookFileId) {
        BookFile bookFile = bookFileRepository.findById(bookFileId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Book file not found"));

        Book book = bookFile.getBook();
        if (book != null && !book.getCreatedBy().getId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not own this book");
        }

        return annotationRepository.findByUserIdAndBookFileIdOrderByCreatedAtAsc(userId, bookFileId)
                .stream()
                .map(AnnotationResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AnnotationResponse> getAnnotationsByBook(UUID userId, UUID bookId) {
        return annotationRepository.findByUserIdAndBookIdOrderByCreatedAtAsc(userId, bookId)
                .stream()
                .map(AnnotationResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AnnotationResponse> getQuotes(UUID userId, UUID bookId) {
        if (bookId != null) {
            return annotationRepository.findByUserIdAndBookIdAndTypeOrderByCreatedAtDesc(userId, bookId, AnnotationType.QUOTE)
                    .stream()
                    .map(AnnotationResponse::fromEntity)
                    .toList();
        }
        return annotationRepository.findByUserIdAndTypeOrderByCreatedAtDesc(userId, AnnotationType.QUOTE)
                .stream()
                .map(AnnotationResponse::fromEntity)
                .toList();
    }

    public AnnotationResponse updateAnnotation(UUID userId, UUID annotationId, UpdateAnnotationRequest request) {
        Annotation annotation = annotationRepository.findByIdAndUserId(annotationId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Annotation not found"));

        if (request.noteText() != null) {
            annotation.setNoteText(request.noteText());
        }
        if (request.color() != null && !request.color().isBlank()) {
            annotation.setColor(request.color());
        }
        annotation.setUpdatedAt(OffsetDateTime.now());

        Annotation updated = annotationRepository.save(annotation);
        return AnnotationResponse.fromEntity(updated);
    }

    public void deleteAnnotation(UUID userId, UUID annotationId) {
        Annotation annotation = annotationRepository.findByIdAndUserId(annotationId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Annotation not found"));

        annotationRepository.delete(annotation);
    }
}
