package com.readingsanctuary.api.readerposition.service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.enums.ReadingStatus;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.common.enums.ReadingLocationType;
import com.readingsanctuary.api.readerposition.dto.ReadingPositionResponse;
import com.readingsanctuary.api.readerposition.dto.SaveReadingPositionRequest;
import com.readingsanctuary.api.readerposition.entity.BookReadingPosition;
import com.readingsanctuary.api.readerposition.repository.BookReadingPositionRepository;
import com.readingsanctuary.api.sync.service.SyncChangePublisher;
import org.springframework.beans.factory.annotation.Autowired;

@Service
@Transactional
public class BookReadingPositionService {

    private final BookReadingPositionRepository positionRepository;
    private final BookRepository bookRepository;
    private final BookFileRepository bookFileRepository;
    private final SyncChangePublisher changePublisher;

    public BookReadingPositionService(
            BookReadingPositionRepository positionRepository,
            BookRepository bookRepository,
            BookFileRepository bookFileRepository) {
        this(positionRepository, bookRepository, bookFileRepository, null);
    }

    @Autowired
    public BookReadingPositionService(
            BookReadingPositionRepository positionRepository,
            BookRepository bookRepository,
            BookFileRepository bookFileRepository,
            @Autowired(required = false) SyncChangePublisher changePublisher) {
        this.positionRepository = positionRepository;
        this.bookRepository = bookRepository;
        this.bookFileRepository = bookFileRepository;
        this.changePublisher = changePublisher;
    }

    public ReadingPositionResponse saveOrUpdate(
            UUID userId, UUID bookId, UUID fileId, SaveReadingPositionRequest request) {

        Book book = getOwnedBook(bookId, userId);
        BookFile file = getBookFile(fileId, bookId);
        validateFormat(file, request.locationType());

        BookReadingPosition position = positionRepository
                .findByBook_IdAndBookFile_Id(bookId, fileId)
                .orElseGet(() -> {
                    BookReadingPosition p = new BookReadingPosition();
                    p.setBook(book);
                    p.setBookFile(file);
                    return p;
                });

        position.setLocationType(request.locationType());
        position.setLocationValue(request.locationValue());
        position.setPageNumber(request.pageNumber());
        position.setTotalPages(request.totalPages());
        position.setProgressPercentage(request.progressPercentage());
        position.setUpdatedAt(OffsetDateTime.now());

        BookReadingPosition saved = positionRepository.save(position);

        // Update book reading state without overwriting completed books
        book.setLastReadAt(OffsetDateTime.now());
        if (book.getReadingStatus() == ReadingStatus.TO_READ) {
            book.setReadingStatus(ReadingStatus.CURRENTLY_READING);
            if (book.getStartedAt() == null) {
                book.setStartedAt(LocalDate.now());
            }
        }
        if (request.locationType() == ReadingLocationType.PDF_PAGE && request.pageNumber() != null) {
            book.setCurrentPage(request.pageNumber());
            if (request.totalPages() != null) {
                book.setTotalPages(request.totalPages());
            }
        }
        bookRepository.save(book);

        ReadingPositionResponse response = toResponse(saved);
        if (changePublisher != null) {
            changePublisher.publishUpdate(userId, "READING_POSITION", saved.getId().toString(), 1L, response);
        }
        return response;
    }

    @Transactional(readOnly = true)
    public Optional<ReadingPositionResponse> getPosition(UUID userId, UUID bookId, UUID fileId) {
        getOwnedBook(bookId, userId);
        getBookFile(fileId, bookId);

        return positionRepository
                .findByBook_IdAndBookFile_Id(bookId, fileId)
                .map(this::toResponse);
    }

    public void resetPosition(UUID userId, UUID bookId, UUID fileId) {
        getOwnedBook(bookId, userId);
        getBookFile(fileId, bookId);

        positionRepository.deleteByBook_IdAndBookFile_Id(bookId, fileId);
        if (changePublisher != null) {
            changePublisher.publishDelete(userId, "READING_POSITION", bookId + ":" + fileId, 1L);
        }
    }

    private Book getOwnedBook(UUID bookId, UUID userId) {
        return bookRepository
                .findByIdAndCreatedBy_Id(bookId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Book not found"));
    }

    private BookFile getBookFile(UUID fileId, UUID bookId) {
        return bookFileRepository
                .findByIdAndBook_Id(fileId, bookId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "File not found for this book"));
    }

    private void validateFormat(BookFile file, ReadingLocationType type) {
        String format = file.getFileFormat();
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

    private ReadingPositionResponse toResponse(BookReadingPosition p) {
        return new ReadingPositionResponse(
                p.getId(),
                p.getBook().getId(),
                p.getBookFile().getId(),
                p.getLocationType(),
                p.getLocationValue(),
                p.getPageNumber(),
                p.getTotalPages(),
                p.getProgressPercentage(),
                p.getUpdatedAt()
        );
    }
}
