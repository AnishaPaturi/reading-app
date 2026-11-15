package com.readingsanctuary.api.annotation;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.annotation.dto.AnnotationResponse;
import com.readingsanctuary.api.annotation.dto.CreateAnnotationRequest;
import com.readingsanctuary.api.annotation.dto.UpdateAnnotationRequest;
import com.readingsanctuary.api.annotation.entity.Annotation;
import com.readingsanctuary.api.annotation.entity.AnnotationType;
import com.readingsanctuary.api.annotation.repository.AnnotationRepository;
import com.readingsanctuary.api.annotation.service.AnnotationService;
import com.readingsanctuary.api.book.entity.Book;
import com.readingsanctuary.api.bookfile.entity.BookFile;
import com.readingsanctuary.api.bookfile.repository.BookFileRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AnnotationServiceTest {

    @Mock
    private AnnotationRepository annotationRepository;

    @Mock
    private BookFileRepository bookFileRepository;

    @Mock
    private UserRepository userRepository;

    private AnnotationService annotationService;

    private UUID userId;
    private UUID bookId;
    private UUID bookFileId;
    private User testUser;
    private Book testBook;
    private BookFile testBookFile;

    @BeforeEach
    void setUp() {
        annotationService = new AnnotationService(annotationRepository, bookFileRepository, userRepository);

        userId = UUID.randomUUID();
        bookId = UUID.randomUUID();
        bookFileId = UUID.randomUUID();

        testUser = new User("test@example.com", "passwordHash");
        ReflectionTestUtils.setField(testUser, "id", userId);

        testBook = new Book();
        ReflectionTestUtils.setField(testBook, "id", bookId);
        testBook.setCreatedBy(testUser);

        testBookFile = new BookFile();
        ReflectionTestUtils.setField(testBookFile, "id", bookFileId);
        ReflectionTestUtils.setField(testBookFile, "book", testBook);
    }

    @Test
    void createHighlightAnnotation_Success() {
        CreateAnnotationRequest req = new CreateAnnotationRequest(
            bookId,
            bookFileId,
            "HIGHLIGHT",
            "Allied survival is absolute.",
            null,
            "#F5E7A8",
            57,
            "{\"rectangles\":[{\"left\":0.18,\"top\":0.42,\"width\":0.63,\"height\":0.035}]}"
        );

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(bookFileRepository.findById(bookFileId)).thenReturn(Optional.of(testBookFile));
        when(annotationRepository.save(any(Annotation.class))).thenAnswer(invocation -> {
            Annotation a = invocation.getArgument(0);
            ReflectionTestUtils.setField(a, "id", UUID.randomUUID());
            a.setCreatedAt(OffsetDateTime.now());
            a.setUpdatedAt(OffsetDateTime.now());
            return a;
        });

        AnnotationResponse response = annotationService.createAnnotation(userId, req);

        assertThat(response).isNotNull();
        assertThat(response.type()).isEqualTo("HIGHLIGHT");
        assertThat(response.selectedText()).isEqualTo("Allied survival is absolute.");
        assertThat(response.color()).isEqualTo("#F5E7A8");
        assertThat(response.pageNumber()).isEqualTo(57);
        assertThat(response.bookFileId()).isEqualTo(bookFileId);
        verify(annotationRepository).save(any(Annotation.class));
    }

    @Test
    void createNoteAnnotation_Success() {
        CreateAnnotationRequest req = new CreateAnnotationRequest(
            bookId,
            bookFileId,
            "NOTE",
            "Allied survival is absolute.",
            "Key theme of this chapter.",
            null,
            57,
            "{\"cfi\":\"epubcfi(/6/12!/4/2)\"}"
        );

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(bookFileRepository.findById(bookFileId)).thenReturn(Optional.of(testBookFile));
        when(annotationRepository.save(any(Annotation.class))).thenAnswer(invocation -> {
            Annotation a = invocation.getArgument(0);
            ReflectionTestUtils.setField(a, "id", UUID.randomUUID());
            a.setCreatedAt(OffsetDateTime.now());
            a.setUpdatedAt(OffsetDateTime.now());
            return a;
        });

        AnnotationResponse response = annotationService.createAnnotation(userId, req);

        assertThat(response).isNotNull();
        assertThat(response.type()).isEqualTo("NOTE");
        assertThat(response.noteText()).isEqualTo("Key theme of this chapter.");
        assertThat(response.selectedText()).isEqualTo("Allied survival is absolute.");
        assertThat(response.locationData()).contains("epubcfi");
    }

    @Test
    void createAnnotation_ForbiddenWhenNotOwner() {
        User otherUser = new User("other@example.com", "otherHash");
        ReflectionTestUtils.setField(otherUser, "id", UUID.randomUUID());
        testBook.setCreatedBy(otherUser);

        CreateAnnotationRequest req = new CreateAnnotationRequest(
            bookId,
            bookFileId,
            "HIGHLIGHT",
            "text",
            null,
            "#F5E7A8",
            1,
            "{}"
        );

        when(userRepository.findById(userId)).thenReturn(Optional.of(testUser));
        when(bookFileRepository.findById(bookFileId)).thenReturn(Optional.of(testBookFile));

        assertThatThrownBy(() -> annotationService.createAnnotation(userId, req))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("You do not own this book");
    }

    @Test
    void updateAnnotation_UpdatesNoteAndColor() {
        UUID annotationId = UUID.randomUUID();
        Annotation annotation = new Annotation();
        ReflectionTestUtils.setField(annotation, "id", annotationId);
        annotation.setUser(testUser);
        annotation.setBook(testBook);
        annotation.setBookFile(testBookFile);
        annotation.setType(AnnotationType.NOTE);
        annotation.setNoteText("Old note");
        annotation.setColor("#F5E7A8");
        annotation.setCreatedAt(OffsetDateTime.now());
        annotation.setUpdatedAt(OffsetDateTime.now());

        when(annotationRepository.findByIdAndUserId(annotationId, userId)).thenReturn(Optional.of(annotation));
        when(annotationRepository.save(any(Annotation.class))).thenReturn(annotation);

        UpdateAnnotationRequest updateReq = new UpdateAnnotationRequest("Updated note thoughts", "#FAD4D8");
        AnnotationResponse updated = annotationService.updateAnnotation(userId, annotationId, updateReq);

        assertThat(updated.noteText()).isEqualTo("Updated note thoughts");
        assertThat(updated.color()).isEqualTo("#FAD4D8");
    }

    @Test
    void deleteAnnotation_Success() {
        UUID annotationId = UUID.randomUUID();
        Annotation annotation = new Annotation();
        ReflectionTestUtils.setField(annotation, "id", annotationId);
        annotation.setUser(testUser);

        when(annotationRepository.findByIdAndUserId(annotationId, userId)).thenReturn(Optional.of(annotation));

        annotationService.deleteAnnotation(userId, annotationId);

        verify(annotationRepository).delete(annotation);
    }
}
