package com.readingsanctuary.api.highlight.service;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.common.enums.HighlightColor;
import com.readingsanctuary.api.common.enums.ReadingLocationType;
import com.readingsanctuary.api.highlight.dto.*;
import com.readingsanctuary.api.highlight.entity.BookHighlight;
import com.readingsanctuary.api.highlight.repository.BookHighlightRepository;

@Service
@Transactional
public class HighlightService {

    private final BookHighlightRepository highlightRepository;
    private final BookRepository bookRepository;
    private final BookFileRepository bookFileRepository;

    public HighlightService(
            BookHighlightRepository highlightRepository,
            BookRepository bookRepository,
            BookFileRepository bookFileRepository) {
        this.highlightRepository = highlightRepository;
        this.bookRepository = bookRepository;
        this.bookFileRepository = bookFileRepository;
    }

    public HighlightResponse create(
            UUID userId, UUID bookId,
            CreateHighlightRequest request) {

        Book book = getOwnedBook(bookId, userId);

        BookFile file = bookFileRepository
                .findByIdAndBook_Id(request.bookFileId(), bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "File not found for this book"));

        validateFormat(file, request.locationType());

        BookHighlight highlight = new BookHighlight();
        highlight.setBook(book);
        highlight.setBookFile(file);
        highlight.setSelectedText(request.selectedText());
        highlight.setLocationType(request.locationType());
        highlight.setStartLocation(request.startLocation());
        highlight.setEndLocation(request.endLocation());
        highlight.setPageNumber(request.pageNumber());
        highlight.setColor(request.color() == null
                ? HighlightColor.YELLOW
                : request.color());
        highlight.setAnnotationNote(request.annotationNote());

        return toResponse(highlightRepository.save(highlight));
    }

    @Transactional(readOnly = true)
    public List<HighlightResponse> getAll(
            UUID userId, UUID bookId) {

        getOwnedBook(bookId, userId);

        return highlightRepository
                .findAllByBook_IdOrderByCreatedAtDesc(bookId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public HighlightResponse update(
            UUID userId, UUID bookId, UUID highlightId,
            UpdateHighlightRequest request) {

        getOwnedBook(bookId, userId);

        BookHighlight highlight = highlightRepository
                .findByIdAndBook_Id(highlightId, bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Highlight not found"));

        if (request.color() != null) {
            highlight.setColor(request.color());
        }

        if (request.annotationNote() != null) {
            highlight.setAnnotationNote(request.annotationNote());
        }

        return toResponse(highlightRepository.save(highlight));
    }

    public void delete(
            UUID userId, UUID bookId, UUID highlightId) {

        getOwnedBook(bookId, userId);

        BookHighlight highlight = highlightRepository
                .findByIdAndBook_Id(highlightId, bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Highlight not found"));

        highlightRepository.delete(highlight);
    }

    private Book getOwnedBook(UUID bookId, UUID userId) {
        return bookRepository
                .findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));
    }

    private void validateFormat(
            BookFile file, ReadingLocationType type) {

        String format = file.getFileFormat().toString();

        boolean valid = switch (type) {
            case PDF_PAGE -> format.equalsIgnoreCase("PDF");
            case EPUB_CFI -> format.equalsIgnoreCase("EPUB");
            case DOCX_ANCHOR -> format.equalsIgnoreCase("DOCX");
        };

        if (!valid) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Reading location type does not match uploaded file format");
        }
    }

    private HighlightResponse toResponse(BookHighlight h) {
        return new HighlightResponse(
                h.getId(),
                h.getBook().getId(),
                h.getBookFile().getId(),
                h.getSelectedText(),
                h.getLocationType(),
                h.getStartLocation(),
                h.getEndLocation(),
                h.getPageNumber(),
                h.getColor(),
                h.getAnnotationNote(),
                h.getCreatedAt(),
                h.getUpdatedAt()
        );
    }
}
