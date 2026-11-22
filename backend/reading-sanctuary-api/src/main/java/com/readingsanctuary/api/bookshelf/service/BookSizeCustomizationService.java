package com.readingsanctuary.api.bookshelf.service;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookshelf.dto.BookSizeCustomizationDto;
import com.readingsanctuary.api.bookshelf.entity.BookSizeCustomization;
import com.readingsanctuary.api.bookshelf.repository.BookSizeCustomizationRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
@Transactional
public class BookSizeCustomizationService {

    private final BookSizeCustomizationRepository customizationRepository;
    private final BookRepository bookRepository;
    private final UserRepository userRepository;

    public BookSizeCustomizationService(
            BookSizeCustomizationRepository customizationRepository,
            BookRepository bookRepository,
            UserRepository userRepository) {
        this.customizationRepository = customizationRepository;
        this.bookRepository = bookRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<BookSizeCustomizationDto> getCustomizations(UUID userId) {
        return customizationRepository.findAllByUser_Id(userId).stream()
                .map(c -> new BookSizeCustomizationDto(
                        c.getBook().getId(),
                        c.getHeightFactor(),
                        c.getPresetSize()
                ))
                .toList();
    }

    public BookSizeCustomizationDto saveCustomization(UUID userId, BookSizeCustomizationDto dto) {
        User user = userRepository.getReferenceById(userId);
        Book book = bookRepository.getReferenceById(dto.bookId());

        BookSizeCustomization entity = customizationRepository
                .findByUser_IdAndBook_Id(userId, dto.bookId())
                .orElse(new BookSizeCustomization(user, book, dto.heightFactor(), dto.presetSize()));

        entity.setHeightFactor(dto.heightFactor());
        entity.setPresetSize(dto.presetSize() != null ? dto.presetSize() : "M");
        BookSizeCustomization saved = customizationRepository.save(entity);

        return new BookSizeCustomizationDto(saved.getBook().getId(), saved.getHeightFactor(), saved.getPresetSize());
    }

    public void resetBookCustomization(UUID userId, UUID bookId) {
        customizationRepository.deleteByUser_IdAndBook_Id(userId, bookId);
    }

    public void resetAllCustomizations(UUID userId) {
        customizationRepository.deleteAllByUser_Id(userId);
    }
}
