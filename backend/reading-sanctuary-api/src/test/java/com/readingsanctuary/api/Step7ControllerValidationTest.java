package com.readingsanctuary.api;

import java.time.OffsetDateTime;
import java.util.Collections;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

import com.readingsanctuary.api.bookmark.controller.BookmarkController;
import com.readingsanctuary.api.bookmark.dto.BookmarkResponse;
import com.readingsanctuary.api.bookmark.service.BookmarkService;
import com.readingsanctuary.api.common.enums.HighlightColor;
import com.readingsanctuary.api.common.enums.ReadingLocationType;
import com.readingsanctuary.api.highlight.controller.HighlightController;
import com.readingsanctuary.api.highlight.dto.HighlightResponse;
import com.readingsanctuary.api.highlight.service.HighlightService;
import com.readingsanctuary.api.note.controller.BookNoteController;
import com.readingsanctuary.api.note.dto.BookNoteResponse;
import com.readingsanctuary.api.note.service.BookNoteService;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class Step7ControllerValidationTest {

    @Mock
    private BookmarkService bookmarkService;

    @Mock
    private HighlightService highlightService;

    @Mock
    private BookNoteService bookNoteService;

    private MockMvc bookmarkMockMvc;
    private MockMvc highlightMockMvc;
    private MockMvc noteMockMvc;

    private final UUID testUserId = UUID.randomUUID();
    private final UUID testBookId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        HandlerMethodArgumentResolver jwtResolver = new HandlerMethodArgumentResolver() {
            @Override
            public boolean supportsParameter(MethodParameter parameter) {
                return parameter.hasParameterAnnotation(AuthenticationPrincipal.class)
                        && parameter.getParameterType().equals(Jwt.class);
            }

            @Override
            public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,
                                          NativeWebRequest webRequest, WebDataBinderFactory binderFactory) {
                return Jwt.withTokenValue("mock-token")
                        .header("alg", "none")
                        .subject(testUserId.toString())
                        .build();
            }
        };

        bookmarkMockMvc = MockMvcBuilders.standaloneSetup(new BookmarkController(bookmarkService))
                .setCustomArgumentResolvers(jwtResolver)
                .build();

        highlightMockMvc = MockMvcBuilders.standaloneSetup(new HighlightController(highlightService))
                .setCustomArgumentResolvers(jwtResolver)
                .build();

        noteMockMvc = MockMvcBuilders.standaloneSetup(new BookNoteController(bookNoteService))
                .setCustomArgumentResolvers(jwtResolver)
                .build();
    }

    @Test
    void createBookmark_ValidationFails_WhenMissingRequiredFields() throws Exception {
        String invalidJson = """
                {
                    "label": "Test"
                }
                """;

        bookmarkMockMvc.perform(post("/api/v1/books/{bookId}/bookmarks", testBookId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createBookmark_ValidationFails_WhenPageNumberNegative() throws Exception {
        String invalidJson = String.format("""
                {
                    "bookFileId": "%s",
                    "locationType": "PDF_PAGE",
                    "locationValue": "page=-1",
                    "pageNumber": -1
                }
                """, UUID.randomUUID());

        bookmarkMockMvc.perform(post("/api/v1/books/{bookId}/bookmarks", testBookId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createBookmark_Success() throws Exception {
        UUID fileId = UUID.randomUUID();
        UUID bookmarkId = UUID.randomUUID();

        BookmarkResponse response = new BookmarkResponse(
                bookmarkId, testBookId, fileId, "Chapter 1", "Note",
                ReadingLocationType.PDF_PAGE, "page=15", 15,
                OffsetDateTime.now(), OffsetDateTime.now()
        );

        when(bookmarkService.create(eq(testUserId), eq(testBookId), any())).thenReturn(response);

        String validJson = String.format("""
                {
                    "bookFileId": "%s",
                    "label": "Chapter 1",
                    "note": "Note",
                    "locationType": "PDF_PAGE",
                    "locationValue": "page=15",
                    "pageNumber": 15
                }
                """, fileId);

        bookmarkMockMvc.perform(post("/api/v1/books/{bookId}/bookmarks", testBookId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(bookmarkId.toString()))
                .andExpect(jsonPath("$.pageNumber").value(15));
    }

    @Test
    void createHighlight_ValidationFails_WhenSelectedTextBlank() throws Exception {
        String invalidJson = String.format("""
                {
                    "bookFileId": "%s",
                    "selectedText": "",
                    "locationType": "PDF_PAGE",
                    "startLocation": "start",
                    "endLocation": "end"
                }
                """, UUID.randomUUID());

        highlightMockMvc.perform(post("/api/v1/books/{bookId}/highlights", testBookId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createHighlight_Success() throws Exception {
        UUID fileId = UUID.randomUUID();
        UUID highlightId = UUID.randomUUID();

        HighlightResponse response = new HighlightResponse(
                highlightId, testBookId, fileId, "Highlight text",
                ReadingLocationType.PDF_PAGE, "page=1", "page=2", 1,
                HighlightColor.YELLOW, "Note",
                OffsetDateTime.now(), OffsetDateTime.now()
        );

        when(highlightService.create(eq(testUserId), eq(testBookId), any())).thenReturn(response);

        String validJson = String.format("""
                {
                    "bookFileId": "%s",
                    "selectedText": "Highlight text",
                    "locationType": "PDF_PAGE",
                    "startLocation": "page=1",
                    "endLocation": "page=2",
                    "pageNumber": 1,
                    "color": "YELLOW"
                }
                """, fileId);

        highlightMockMvc.perform(post("/api/v1/books/{bookId}/highlights", testBookId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(highlightId.toString()))
                .andExpect(jsonPath("$.selectedText").value("Highlight text"));
    }

    @Test
    void createBookNote_ValidationFails_WhenTitleBlank() throws Exception {
        String invalidJson = """
                {
                    "title": "",
                    "content": "Some content"
                }
                """;

        noteMockMvc.perform(post("/api/v1/books/{bookId}/notes", testBookId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createBookNote_Success() throws Exception {
        UUID noteId = UUID.randomUUID();

        BookNoteResponse response = new BookNoteResponse(
                noteId, testBookId, "Note Title", "Note Content",
                OffsetDateTime.now(), OffsetDateTime.now()
        );

        when(bookNoteService.create(eq(testUserId), eq(testBookId), any())).thenReturn(response);

        String validJson = """
                {
                    "title": "Note Title",
                    "content": "Note Content"
                }
                """;

        noteMockMvc.perform(post("/api/v1/books/{bookId}/notes", testBookId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(noteId.toString()))
                .andExpect(jsonPath("$.title").value("Note Title"));
    }

    @Test
    void deleteEndpoints_ReturnNoContent() throws Exception {
        UUID itemId = UUID.randomUUID();

        bookmarkMockMvc.perform(delete("/api/v1/books/{bookId}/bookmarks/{bookmarkId}", testBookId, itemId))
                .andExpect(status().isNoContent());

        highlightMockMvc.perform(delete("/api/v1/books/{bookId}/highlights/{highlightId}", testBookId, itemId))
                .andExpect(status().isNoContent());

        noteMockMvc.perform(delete("/api/v1/books/{bookId}/notes/{noteId}", testBookId, itemId))
                .andExpect(status().isNoContent());
    }
}
