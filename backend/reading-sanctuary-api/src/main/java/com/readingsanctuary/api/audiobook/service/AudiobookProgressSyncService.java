package com.readingsanctuary.api.audiobook.service;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.audiobook.dto.AudiobookProgressDto;
import com.readingsanctuary.api.audiobook.entity.AudiobookProgress;
import com.readingsanctuary.api.audiobook.repository.AudiobookProgressRepository;

@Service
public class AudiobookProgressSyncService {

    private final AudiobookProgressRepository progressRepository;

    public AudiobookProgressSyncService(AudiobookProgressRepository progressRepository) {
        this.progressRepository = progressRepository;
    }

    @Transactional
    public AudiobookProgressDto updateProgress(UUID userId, UUID audiobookId, AudiobookProgressDto dto) {
        Optional<AudiobookProgress> existingOpt = progressRepository.findByAudiobookIdAndUserId(audiobookId, userId);
        AudiobookProgress progress;

        if (existingOpt.isPresent()) {
            progress = existingOpt.get();
            progress.setCurrentTrackId(dto.currentTrackId());
            progress.setTrackIndex(dto.trackIndex() != null ? dto.trackIndex() : 0);
            progress.setPositionMs(dto.positionMs() != null ? dto.positionMs() : 0L);
            progress.setTotalDurationMs(dto.totalDurationMs() != null ? dto.totalDurationMs() : 0L);
            progress.setPlaybackSpeed(dto.playbackSpeed());
            progress.setCompleted(dto.completed() != null ? dto.completed() : false);
            progress.setLastListenedAt(OffsetDateTime.now());
        } else {
            progress = new AudiobookProgress(
                audiobookId,
                userId,
                dto.currentTrackId(),
                dto.trackIndex(),
                dto.positionMs(),
                dto.totalDurationMs(),
                dto.playbackSpeed(),
                dto.completed()
            );
        }

        AudiobookProgress saved = progressRepository.save(progress);
        return toDto(saved);
    }

    @Transactional(readOnly = true)
    public Optional<AudiobookProgressDto> getProgress(UUID userId, UUID audiobookId) {
        return progressRepository.findByAudiobookIdAndUserId(audiobookId, userId)
            .map(this::toDto);
    }

    private AudiobookProgressDto toDto(AudiobookProgress p) {
        return new AudiobookProgressDto(
            p.getAudiobookId(),
            p.getCurrentTrackId(),
            p.getTrackIndex(),
            p.getPositionMs(),
            p.getTotalDurationMs(),
            p.getPlaybackSpeed(),
            p.getCompleted(),
            p.getLastListenedAt()
        );
    }
}
