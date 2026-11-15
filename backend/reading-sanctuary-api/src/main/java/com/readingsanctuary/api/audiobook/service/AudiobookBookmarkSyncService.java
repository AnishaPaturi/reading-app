package com.readingsanctuary.api.audiobook.service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.audiobook.dto.AudiobookBookmarkDto;
import com.readingsanctuary.api.audiobook.entity.AudiobookBookmark;
import com.readingsanctuary.api.audiobook.repository.AudiobookBookmarkRepository;

@Service
public class AudiobookBookmarkSyncService {

    private final AudiobookBookmarkRepository bookmarkRepository;

    public AudiobookBookmarkSyncService(AudiobookBookmarkRepository bookmarkRepository) {
        this.bookmarkRepository = bookmarkRepository;
    }

    @Transactional
    public AudiobookBookmarkDto addBookmark(UUID userId, UUID audiobookId, AudiobookBookmarkDto dto) {
        AudiobookBookmark bookmark = new AudiobookBookmark(
            dto.id(),
            audiobookId,
            userId,
            dto.trackId(),
            dto.trackIndex(),
            dto.positionMs(),
            dto.title(),
            dto.note(),
            dto.category(),
            dto.favorite()
        );
        AudiobookBookmark saved = bookmarkRepository.save(bookmark);
        return toDto(saved);
    }

    @Transactional(readOnly = true)
    public List<AudiobookBookmarkDto> getBookmarksForBook(UUID userId, UUID audiobookId) {
        return bookmarkRepository.findByAudiobookIdAndUserIdOrderByCreatedAtDesc(audiobookId, userId)
            .stream()
            .map(this::toDto)
            .toList();
    }

    @Transactional(readOnly = true)
    public List<AudiobookBookmarkDto> getAllUserBookmarks(UUID userId) {
        return bookmarkRepository.findByUserIdOrderByCreatedAtDesc(userId)
            .stream()
            .map(this::toDto)
            .toList();
    }

    @Transactional
    public Optional<AudiobookBookmarkDto> updateBookmark(UUID userId, UUID bookmarkId, AudiobookBookmarkDto dto) {
        return bookmarkRepository.findByIdAndUserId(bookmarkId, userId)
            .map(bm -> {
                bm.setTitle(dto.title());
                bm.setNote(dto.note());
                bm.setCategory(dto.category());
                if (dto.favorite() != null) {
                    bm.setFavorite(dto.favorite());
                }
                return toDto(bookmarkRepository.save(bm));
            });
    }

    @Transactional
    public void deleteBookmark(UUID userId, UUID bookmarkId) {
        bookmarkRepository.deleteByIdAndUserId(bookmarkId, userId);
    }

    private AudiobookBookmarkDto toDto(AudiobookBookmark b) {
        return new AudiobookBookmarkDto(
            b.getId(),
            b.getAudiobookId(),
            b.getTrackId(),
            b.getTrackIndex(),
            b.getPositionMs(),
            b.getTitle(),
            b.getNote(),
            b.getCategory(),
            b.getFavorite(),
            b.getCreatedAt()
        );
    }
}
