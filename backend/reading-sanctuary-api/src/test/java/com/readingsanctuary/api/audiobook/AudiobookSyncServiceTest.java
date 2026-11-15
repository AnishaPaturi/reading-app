package com.readingsanctuary.api.audiobook;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.readingsanctuary.api.audiobook.dto.AudioTrackDto;
import com.readingsanctuary.api.audiobook.dto.AudiobookResponseDto;
import com.readingsanctuary.api.audiobook.dto.AudiobookSyncDto;
import com.readingsanctuary.api.audiobook.entity.Audiobook;
import com.readingsanctuary.api.audiobook.repository.AudioTrackRepository;
import com.readingsanctuary.api.audiobook.repository.AudiobookRepository;
import com.readingsanctuary.api.audiobook.service.AudiobookSyncService;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AudiobookSyncServiceTest {

    @Mock
    private AudiobookRepository audiobookRepository;

    @Mock
    private AudioTrackRepository trackRepository;

    @InjectMocks
    private AudiobookSyncService syncService;

    private UUID userId;
    private UUID bookId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        bookId = UUID.randomUUID();
    }

    @Test
    void syncAudiobook_createsNewBookAndTracks() {
        AudioTrackDto track1 = new AudioTrackDto(UUID.randomUUID(), "01-track.mp3", 1, 180000L, "MP3", "Chapter 1");
        AudioTrackDto track2 = new AudioTrackDto(UUID.randomUUID(), "02-track.mp3", 2, 220000L, "MP3", "Chapter 2");

        AudiobookSyncDto syncDto = new AudiobookSyncDto(
            bookId,
            "The Silent Patient",
            "Alex Michaelides",
            "Jack Hawkins",
            "A thriller",
            "/covers/silent.jpg",
            "/audiobooks/silent",
            400000L,
            2,
            "notStarted",
            List.of(track1, track2)
        );

        when(audiobookRepository.findByIdAndUserId(bookId, userId)).thenReturn(Optional.empty());
        when(audiobookRepository.save(any(Audiobook.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AudiobookResponseDto result = syncService.syncAudiobook(userId, syncDto);

        assertThat(result).isNotNull();
        assertThat(result.id()).isEqualTo(bookId);
        assertThat(result.title()).isEqualTo("The Silent Patient");
        assertThat(result.author()).isEqualTo("Alex Michaelides");
        assertThat(result.totalTracks()).isEqualTo(2);

        verify(audiobookRepository).save(any(Audiobook.class));
        verify(trackRepository).saveAll(any());
    }

    @Test
    void getUserAudiobooks_returnsUserCollection() {
        Audiobook book = new Audiobook(
            bookId,
            userId,
            "Project Hail Mary",
            "Andy Weir",
            "Ray Porter",
            "Sci-fi",
            null,
            null,
            500000L,
            1,
            "current"
        );

        when(audiobookRepository.findByUserIdOrderByCreatedAtDesc(userId)).thenReturn(List.of(book));

        List<AudiobookResponseDto> list = syncService.getUserAudiobooks(userId);

        assertThat(list).hasSize(1);
        assertThat(list.get(0).title()).isEqualTo("Project Hail Mary");
    }

    @Test
    void deleteAudiobook_callsRepository() {
        syncService.deleteAudiobook(userId, bookId);
        verify(audiobookRepository).deleteByIdAndUserId(bookId, userId);
    }
}
