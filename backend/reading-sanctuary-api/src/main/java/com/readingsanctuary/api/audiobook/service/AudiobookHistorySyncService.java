package com.readingsanctuary.api.audiobook.service;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.audiobook.dto.ListeningSessionDto;
import com.readingsanctuary.api.audiobook.entity.AudiobookListeningSession;
import com.readingsanctuary.api.audiobook.repository.AudiobookListeningSessionRepository;

@Service
public class AudiobookHistorySyncService {

    private final AudiobookListeningSessionRepository sessionRepository;

    public AudiobookHistorySyncService(AudiobookListeningSessionRepository sessionRepository) {
        this.sessionRepository = sessionRepository;
    }

    @Transactional
    public ListeningSessionDto saveListeningSession(UUID userId, UUID audiobookId, ListeningSessionDto dto) {
        AudiobookListeningSession session = new AudiobookListeningSession(
            dto.id(),
            audiobookId,
            userId,
            dto.startedAt(),
            dto.endedAt(),
            dto.actualListeningMs()
        );
        AudiobookListeningSession saved = sessionRepository.save(session);
        return toDto(saved);
    }

    @Transactional(readOnly = true)
    public List<ListeningSessionDto> getUserHistory(UUID userId) {
        return sessionRepository.findByUserIdOrderByStartedAtDesc(userId)
            .stream()
            .map(this::toDto)
            .toList();
    }

    private ListeningSessionDto toDto(AudiobookListeningSession s) {
        return new ListeningSessionDto(
            s.getId(),
            s.getAudiobookId(),
            s.getStartedAt(),
            s.getEndedAt(),
            s.getActualListeningMs()
        );
    }
}
