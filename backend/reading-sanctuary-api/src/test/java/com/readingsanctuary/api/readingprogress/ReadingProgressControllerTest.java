package com.readingsanctuary.api.readingprogress;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
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

import com.readingsanctuary.api.readingprogress.controller.ReadingProgressController;
import com.readingsanctuary.api.readingprogress.dto.ReadingProgressRequest;
import com.readingsanctuary.api.readingprogress.dto.ReadingProgressResponse;
import com.readingsanctuary.api.readingprogress.service.ReadingProgressService;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class ReadingProgressControllerTest {

    @Mock
    private ReadingProgressService progressService;

    private MockMvc mockMvc;

    private final UUID testUserId = UUID.randomUUID();
    private final UUID bookFileId = UUID.randomUUID();

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
                return Jwt.withTokenValue("mock-jwt-token")
                        .header("alg", "none")
                        .claim("sub", testUserId.toString())
                        .build();
            }
        };

        mockMvc = MockMvcBuilders.standaloneSetup(new ReadingProgressController(progressService))
                .setCustomArgumentResolvers(jwtResolver)
                .build();
    }

    @Test
    void getProgress_returns200WhenFound() throws Exception {
        ReadingProgressResponse resp = new ReadingProgressResponse(
                UUID.randomUUID(),
                testUserId,
                UUID.randomUUID(),
                bookFileId,
                "PDF",
                182,
                363,
                null,
                null,
                null,
                null,
                BigDecimal.valueOf(50.138),
                "{}",
                OffsetDateTime.now(),
                OffsetDateTime.now(),
                OffsetDateTime.now(),
                OffsetDateTime.now()
        );

        when(progressService.getProgress(eq(testUserId), eq(bookFileId)))
                .thenReturn(Optional.of(resp));

        mockMvc.perform(get("/api/v1/reading-progress/{bookFileId}", bookFileId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentPage").value(182))
                .andExpect(jsonPath("$.totalPages").value(363))
                .andExpect(jsonPath("$.format").value("PDF"));
    }

    @Test
    void getProgress_returns404WhenNotFound() throws Exception {
        when(progressService.getProgress(eq(testUserId), eq(bookFileId)))
                .thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/reading-progress/{bookFileId}", bookFileId))
                .andExpect(status().isNotFound());
    }

    @Test
    void saveProgress_returns200() throws Exception {
        ReadingProgressResponse resp = new ReadingProgressResponse(
                UUID.randomUUID(),
                testUserId,
                UUID.randomUUID(),
                bookFileId,
                "PDF",
                182,
                363,
                null,
                null,
                null,
                null,
                BigDecimal.valueOf(50.138),
                "{}",
                OffsetDateTime.now(),
                OffsetDateTime.now(),
                OffsetDateTime.now(),
                OffsetDateTime.now()
        );

        when(progressService.saveProgress(eq(testUserId), eq(bookFileId), any(ReadingProgressRequest.class)))
                .thenReturn(resp);

        String json = """
                {
                    "format": "PDF",
                    "currentPage": 182,
                    "totalPages": 363,
                    "progressPercentage": 50.138,
                    "positionData": "{}"
                }
                """;

        mockMvc.perform(put("/api/v1/reading-progress/{bookFileId}", bookFileId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentPage").value(182));
    }

    @Test
    void getAllProgress_returnsList() throws Exception {
        when(progressService.getAllProgress(eq(testUserId)))
                .thenReturn(List.of());

        mockMvc.perform(get("/api/v1/reading-progress"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    void resetProgress_returns204() throws Exception {
        mockMvc.perform(delete("/api/v1/reading-progress/{bookFileId}", bookFileId))
                .andExpect(status().isNoContent());

        verify(progressService).resetProgress(eq(testUserId), eq(bookFileId));
    }
}
