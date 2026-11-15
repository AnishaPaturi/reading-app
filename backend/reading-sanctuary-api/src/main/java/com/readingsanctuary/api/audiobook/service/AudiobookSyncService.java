package com.readingsanctuary.api.audiobook.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.audiobook.dto.AudioTrackDto;
import com.readingsanctuary.api.audiobook.dto.AudiobookResponseDto;
import com.readingsanctuary.api.audiobook.dto.AudiobookSyncDto;
import com.readingsanctuary.api.audiobook.entity.AudioTrack;
import com.readingsanctuary.api.audiobook.entity.Audiobook;
import com.readingsanctuary.api.audiobook.repository.AudioTrackRepository;
import com.readingsanctuary.api.audiobook.repository.AudiobookRepository;

@Service
public class AudiobookSyncService {

    private final AudiobookRepository audiobookRepository;
    private final AudioTrackRepository trackRepository;

    public AudiobookSyncService(AudiobookRepository audiobookRepository, AudioTrackRepository trackRepository) {
        this.audiobookRepository = audiobookRepository;
        this.trackRepository = trackRepository;
    }

    @Transactional
    public AudiobookResponseDto syncAudiobook(UUID userId, AudiobookSyncDto dto) {
        Optional<Audiobook> existingOpt = audiobookRepository.findByIdAndUserId(dto.id(), userId);
        Audiobook book;

        if (existingOpt.isPresent()) {
            book = existingOpt.get();
            book.setTitle(dto.title());
            book.setAuthor(dto.author());
            book.setNarrator(dto.narrator());
            book.setDescription(dto.description());
            book.setCoverPath(dto.coverPath());
            book.setFolderPath(dto.folderPath());
            book.setTotalDurationMs(dto.totalDurationMs());
            book.setTotalTracks(dto.totalTracks());
            book.setStatus(dto.status());
        } else {
            book = new Audiobook(
                dto.id(),
                userId,
                dto.title(),
                dto.author(),
                dto.narrator(),
                dto.description(),
                dto.coverPath(),
                dto.folderPath(),
                dto.totalDurationMs(),
                dto.totalTracks(),
                dto.status()
            );
        }

        Audiobook saved = audiobookRepository.save(book);

        if (dto.tracks() != null && !dto.tracks().isEmpty()) {
            List<AudioTrack> tracks = new ArrayList<>();
            for (AudioTrackDto tDto : dto.tracks()) {
                AudioTrack track = new AudioTrack(
                    tDto.id(),
                    saved,
                    tDto.fileName(),
                    tDto.trackOrder(),
                    tDto.durationMs(),
                    tDto.format(),
                    tDto.chapterTitle()
                );
                tracks.add(track);
            }
            trackRepository.saveAll(tracks);
            saved.setTracks(tracks);
        }

        return toDto(saved);
    }

    @Transactional(readOnly = true)
    public List<AudiobookResponseDto> getUserAudiobooks(UUID userId) {
        return audiobookRepository.findByUserIdOrderByCreatedAtDesc(userId)
            .stream()
            .map(this::toDto)
            .toList();
    }

    @Transactional(readOnly = true)
    public Optional<AudiobookResponseDto> getAudiobook(UUID userId, UUID id) {
        return audiobookRepository.findByIdAndUserId(id, userId)
            .map(this::toDto);
    }

    @Transactional
    public void deleteAudiobook(UUID userId, UUID id) {
        audiobookRepository.deleteByIdAndUserId(id, userId);
    }

    private AudiobookResponseDto toDto(Audiobook book) {
        List<AudioTrackDto> trackDtos = trackRepository.findByAudiobookIdOrderByTrackOrderAsc(book.getId())
            .stream()
            .map(t -> new AudioTrackDto(
                t.getId(),
                t.getFileName(),
                t.getTrackOrder(),
                t.getDurationMs(),
                t.getFormat(),
                t.getChapterTitle()
            ))
            .toList();

        return new AudiobookResponseDto(
            book.getId(),
            book.getTitle(),
            book.getAuthor(),
            book.getNarrator(),
            book.getDescription(),
            book.getCoverPath(),
            book.getFolderPath(),
            book.getTotalDurationMs(),
            book.getTotalTracks(),
            book.getStatus(),
            book.getCreatedAt(),
            book.getUpdatedAt(),
            trackDtos
        );
    }
}
