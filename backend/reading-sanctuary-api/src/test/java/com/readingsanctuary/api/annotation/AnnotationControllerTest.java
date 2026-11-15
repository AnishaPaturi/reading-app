package com.readingsanctuary.api.annotation;

import java.time.OffsetDateTime;
import java.util.List;
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

import com.readingsanctuary.api.annotation.controller.AnnotationController;
import com.readingsanctuary.api.annotation.dto.AnnotationResponse;
import com.readingsanctuary.api.annotation.dto.CreateAnnotationRequest;
import com.readingsanctuary.api.annotation.dto.UpdateAnnotationRequest;
import com.readingsanctuary.api.annotation.service.AnnotationService;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class AnnotationControllerTest {

    @Mock
    private AnnotationService annotationService;

    private MockMvc mockMvc;

    private final UUID testUserId = UUID.randomUUID();
    private final UUID bookId = UUID.randomUUID();
    private final UUID bookFileId = UUID.randomUUID();
    private final UUID annotationId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        HandlerMethodArgumentResolver jwtResolver = new HandlerMethodArgumentResolver() {
            @Override
            public boolean supportsParameter(MethodParameter parameter) {
                return parameter.hasParameterAnnotation(AuthenticationPrincipal.class);
            }

            @Override
            public Object resolveArgument(MethodParameter parameter,
                                          ModelAndViewContainer mavContainer,
                                          NativeWebRequest webRequest,
                                          WebDataBinderFactory binderFactory) {
                return Jwt.withTokenValue("mock-token")
                        .header("alg", "none")
                        .subject(testUserId.toString())
                        .build();
            }
        };

        AnnotationController controller = new AnnotationController(annotationService);
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setCustomArgumentResolvers(jwtResolver)
                .build();
    }

    @Test
    void createAnnotation_Returns201Created() throws Exception {
        AnnotationResponse mockResponse = new AnnotationResponse(
                annotationId,
                testUserId,
                bookId,
                bookFileId,
                "HIGHLIGHT",
                "Allied survival is absolute.",
                null,
                "#F5E7A8",
                57,
                "{}",
                OffsetDateTime.now(),
                OffsetDateTime.now()
        );

        when(annotationService.createAnnotation(eq(testUserId), any(CreateAnnotationRequest.class)))
                .thenReturn(mockResponse);

        String json = """
                {
                  "bookId": "%s",
                  "bookFileId": "%s",
                  "type": "HIGHLIGHT",
                  "selectedText": "Allied survival is absolute.",
                  "color": "#F5E7A8",
                  "pageNumber": 57,
                  "locationData": "{}"
                }
                """.formatted(bookId, bookFileId);

        mockMvc.perform(post("/api/v1/annotations")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(annotationId.toString()))
                .andExpect(jsonPath("$.type").value("HIGHLIGHT"))
                .andExpect(jsonPath("$.selectedText").value("Allied survival is absolute."))
                .andExpect(jsonPath("$.pageNumber").value(57))
                .andExpect(jsonPath("$.color").value("#F5E7A8"));
    }

    @Test
    void getAnnotationsByBookFile_ReturnsList() throws Exception {
        AnnotationResponse mockResponse = new AnnotationResponse(
                annotationId,
                testUserId,
                bookId,
                bookFileId,
                "NOTE",
                null,
                "Thoughts on page 10",
                null,
                10,
                "{}",
                OffsetDateTime.now(),
                OffsetDateTime.now()
        );

        when(annotationService.getAnnotationsByBookFile(testUserId, bookFileId))
                .thenReturn(List.of(mockResponse));

        mockMvc.perform(get("/api/v1/annotations/book-file/" + bookFileId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(annotationId.toString()))
                .andExpect(jsonPath("$[0].type").value("NOTE"))
                .andExpect(jsonPath("$[0].noteText").value("Thoughts on page 10"));
    }

    @Test
    void updateAnnotation_ReturnsUpdated() throws Exception {
        AnnotationResponse mockResponse = new AnnotationResponse(
                annotationId,
                testUserId,
                bookId,
                bookFileId,
                "NOTE",
                null,
                "Updated note",
                "#FAD4D8",
                10,
                "{}",
                OffsetDateTime.now(),
                OffsetDateTime.now()
        );

        when(annotationService.updateAnnotation(eq(testUserId), eq(annotationId), any(UpdateAnnotationRequest.class)))
                .thenReturn(mockResponse);

        String json = """
                {
                  "noteText": "Updated note",
                  "color": "#FAD4D8"
                }
                """;

        mockMvc.perform(patch("/api/v1/annotations/" + annotationId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.noteText").value("Updated note"))
                .andExpect(jsonPath("$.color").value("#FAD4D8"));
    }

    @Test
    void deleteAnnotation_Returns204NoContent() throws Exception {
        mockMvc.perform(delete("/api/v1/annotations/" + annotationId))
                .andExpect(status().isNoContent());

        verify(annotationService).deleteAnnotation(testUserId, annotationId);
    }
}
