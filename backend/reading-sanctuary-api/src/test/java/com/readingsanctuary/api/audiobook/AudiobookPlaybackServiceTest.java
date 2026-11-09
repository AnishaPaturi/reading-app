package com.readingsanctuary.api.audiobook;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.audiobook.dto.AudioPositionResponse;
import com.readingsanctuary.api.audiobook.dto.SaveAudioPositionRequest;
import com.readingsanctuary.api.audiobook.entity.AudiobookPlaybackPosition;
import com.readingsanctuary.api.audiobook.repository.AudiobookPlaybackPositionRepository;
import com.readingsanctuary.api.audiobook.service.AudiobookPlaybackService;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AudiobookPlaybackServiceTest {

    @Mock
    private AudiobookPlaybackPositionRepository positionRepository;

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @InjectMocks
    private AudiobookPlaybackService playbackService;

    private UUID userId;
    private UUID bookId;
    private UUID fileId;
    private Book book;
    private BookFile mp3File;
    private BookFile pdfFile;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        bookId = UUID.randomUUID();
        fileId = UUID.randomUUID();

        book = new Book();
        ReflectionTestUtils.setField(book, "id", bookId);

        mp3File = new BookFile();
        ReflectionTestUtils.setField(mp3File, "id", fileId);
        mp3File.setBook(book);
        mp3File.setFileFormat("MP3");

        pdfFile = new BookFile();
        ReflectionTestUtils.setField(pdfFile, "id", fileId);
        pdfFile.setBook(book);
        pdfFile.setFileFormat("PDF");
    }

    @Test
    void saveOrUpdate_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(mp3File));
        when(positionRepository.findByBookFile_Id(fileId)).thenReturn(Optional.empty());

        when(positionRepository.save(any(AudiobookPlaybackPosition.class))).thenAnswer(invocation -> {
            AudiobookPlaybackPosition pos = invocation.getArgument(0);
            ReflectionTestUtils.setField(pos, "id", UUID.randomUUID());
            return pos;
        });

        SaveAudioPositionRequest request = new SaveAudioPositionRequest(
                120000L,
                600000L,
                new BigDecimal("1.25"),
                false
        );

        AudioPositionResponse response = playbackService.saveOrUpdate(userId, bookId, fileId, request);

        assertThat(response).isNotNull();
        assertThat(response.bookId()).isEqualTo(bookId);
        assertThat(response.bookFileId()).isEqualTo(fileId);
        assertThat(response.positionMs()).isEqualTo(120000L);
        assertThat(response.durationMs()).isEqualTo(600000L);
        assertThat(response.playbackSpeed()).isEqualByComparingTo(new BigDecimal("1.25"));
        assertThat(response.isCompleted()).isFalse();

        verify(bookRepository).save(book);
        assertThat(book.getLastReadAt()).isNotNull();
    }

    @Test
    void saveOrUpdate_InvalidFormat_ThrowsBadRequest() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(pdfFile));

        SaveAudioPositionRequest request = new SaveAudioPositionRequest(
                1000L,
                2000L,
                BigDecimal.ONE,
                false
        );

        assertThatThrownBy(() -> playbackService.saveOrUpdate(userId, bookId, fileId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void saveOrUpdate_PositionExceedsDuration_ThrowsBadRequest() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(mp3File));

        SaveAudioPositionRequest request = new SaveAudioPositionRequest(
                5000L,
                3000L,
                BigDecimal.ONE,
                false
        );

        assertThatThrownBy(() -> playbackService.saveOrUpdate(userId, bookId, fileId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void saveOrUpdate_SpeedOutOfRange_ThrowsBadRequest() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(mp3File));

        SaveAudioPositionRequest request = new SaveAudioPositionRequest(
                1000L,
                3000L,
                new BigDecimal("3.5"),
                false
        );

        assertThatThrownBy(() -> playbackService.saveOrUpdate(userId, bookId, fileId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void saveOrUpdate_CrossUser_ThrowsNotFound() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.empty());

        SaveAudioPositionRequest request = new SaveAudioPositionRequest(
                1000L,
                3000L,
                BigDecimal.ONE,
                false
        );

        assertThatThrownBy(() -> playbackService.saveOrUpdate(userId, bookId, fileId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    void getPosition_ReturnsExisting() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(mp3File));

        AudiobookPlaybackPosition position = new AudiobookPlaybackPosition();
        ReflectionTestUtils.setField(position, "id", UUID.randomUUID());
        position.setBook(book);
        position.setBookFile(mp3File);
        position.setPositionMs(50000L);
        position.setDurationMs(200000L);
        position.setPlaybackSpeed(new BigDecimal("1.50"));
        position.setCompleted(false);

        when(positionRepository.findByBookFile_Id(fileId)).thenReturn(Optional.of(position));

        Optional<AudioPositionResponse> result = playbackService.getPosition(userId, bookId, fileId);

        assertThat(result).isPresent();
        assertThat(result.get().positionMs()).isEqualTo(50000L);
        assertThat(result.get().durationMs()).isEqualTo(200000L);
    }

    @Test
    void reset_DeletesPosition() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(mp3File));

        AudiobookPlaybackPosition position = new AudiobookPlaybackPosition();
        when(positionRepository.findByBookFile_Id(fileId)).thenReturn(Optional.of(position));

        playbackService.reset(userId, bookId, fileId);

        verify(positionRepository).delete(position);
    }
}
