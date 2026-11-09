package com.readingsanctuary.api.tts;

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

import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.tts.dto.SaveTtsPositionRequest;
import com.readingsanctuary.api.tts.dto.TtsPositionResponse;
import com.readingsanctuary.api.tts.entity.TtsPlaybackPosition;
import com.readingsanctuary.api.tts.repository.TtsPlaybackPositionRepository;
import com.readingsanctuary.api.tts.service.TtsPlaybackService;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TtsPlaybackServiceTest {

    @Mock
    private TtsPlaybackPositionRepository positionRepository;

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @InjectMocks
    private TtsPlaybackService ttsPlaybackService;

    private UUID userId;
    private UUID bookId;
    private UUID fileId;
    private Book book;
    private BookFile epubFile;
    private BookFile mp3File;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        bookId = UUID.randomUUID();
        fileId = UUID.randomUUID();

        book = new Book();
        ReflectionTestUtils.setField(book, "id", bookId);

        epubFile = new BookFile();
        ReflectionTestUtils.setField(epubFile, "id", fileId);
        epubFile.setBook(book);
        epubFile.setFileFormat("EPUB");

        mp3File = new BookFile();
        ReflectionTestUtils.setField(mp3File, "id", fileId);
        mp3File.setBook(book);
        mp3File.setFileFormat("MP3");
    }

    @Test
    void saveOrUpdate_Success() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(epubFile));
        when(positionRepository.findByBook_IdAndBookFile_Id(bookId, fileId)).thenReturn(Optional.empty());

        when(positionRepository.save(any(TtsPlaybackPosition.class))).thenAnswer(invocation -> {
            TtsPlaybackPosition pos = invocation.getArgument(0);
            ReflectionTestUtils.setField(pos, "id", UUID.randomUUID());
            return pos;
        });

        SaveTtsPositionRequest request = new SaveTtsPositionRequest(
                2,
                5,
                120,
                new BigDecimal("45.50")
        );

        TtsPositionResponse response = ttsPlaybackService.saveOrUpdate(userId, bookId, fileId, request);

        assertThat(response).isNotNull();
        assertThat(response.bookId()).isEqualTo(bookId);
        assertThat(response.bookFileId()).isEqualTo(fileId);
        assertThat(response.chapterIndex()).isEqualTo(2);
        assertThat(response.chunkIndex()).isEqualTo(5);
        assertThat(response.characterOffset()).isEqualTo(120);
        assertThat(response.progressPercentage()).isEqualByComparingTo(new BigDecimal("45.50"));

        verify(bookRepository).save(book);
        assertThat(book.getLastReadAt()).isNotNull();
    }

    @Test
    void saveOrUpdate_InvalidFormat_ThrowsBadRequest() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(mp3File));

        SaveTtsPositionRequest request = new SaveTtsPositionRequest(
                0, 0, 0, BigDecimal.ZERO
        );

        assertThatThrownBy(() -> ttsPlaybackService.saveOrUpdate(userId, bookId, fileId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void saveOrUpdate_NegativeOffset_ThrowsBadRequest() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(epubFile));

        SaveTtsPositionRequest request = new SaveTtsPositionRequest(
                -1, 0, 0, BigDecimal.ZERO
        );

        assertThatThrownBy(() -> ttsPlaybackService.saveOrUpdate(userId, bookId, fileId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void saveOrUpdate_ProgressOutOfRange_ThrowsBadRequest() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(epubFile));

        SaveTtsPositionRequest request = new SaveTtsPositionRequest(
                0, 0, 0, new BigDecimal("105.00")
        );

        assertThatThrownBy(() -> ttsPlaybackService.saveOrUpdate(userId, bookId, fileId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void saveOrUpdate_CrossUser_ThrowsNotFound() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.empty());

        SaveTtsPositionRequest request = new SaveTtsPositionRequest(
                0, 0, 0, BigDecimal.ZERO
        );

        assertThatThrownBy(() -> ttsPlaybackService.saveOrUpdate(userId, bookId, fileId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    void getPosition_ReturnsExisting() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(epubFile));

        TtsPlaybackPosition position = new TtsPlaybackPosition();
        ReflectionTestUtils.setField(position, "id", UUID.randomUUID());
        position.setBook(book);
        position.setBookFile(epubFile);
        position.setChapterIndex(1);
        position.setChunkIndex(3);
        position.setCharacterOffset(40);
        position.setProgressPercentage(new BigDecimal("25.00"));

        when(positionRepository.findByBook_IdAndBookFile_Id(bookId, fileId)).thenReturn(Optional.of(position));

        Optional<TtsPositionResponse> result = ttsPlaybackService.getPosition(userId, bookId, fileId);

        assertThat(result).isPresent();
        assertThat(result.get().chapterIndex()).isEqualTo(1);
        assertThat(result.get().chunkIndex()).isEqualTo(3);
    }

    @Test
    void reset_DeletesPosition() {
        when(bookRepository.findByIdAndCreatedBy_Id(bookId, userId)).thenReturn(Optional.of(book));
        when(bookFileRepository.findByIdAndBook_Id(fileId, bookId)).thenReturn(Optional.of(epubFile));

        ttsPlaybackService.resetPosition(userId, bookId, fileId);

        verify(positionRepository).deleteByBook_IdAndBookFile_Id(bookId, fileId);
    }
}
