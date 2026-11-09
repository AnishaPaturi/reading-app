package com.readingsanctuary.api;

import java.time.LocalDate;
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

import com.readingsanctuary.api.analytics.controller.ActivitySessionController;
import com.readingsanctuary.api.analytics.controller.AnalyticsController;
import com.readingsanctuary.api.analytics.controller.ReadingGoalController;
import com.readingsanctuary.api.analytics.dto.*;
import com.readingsanctuary.api.analytics.enums.ActivityType;
import com.readingsanctuary.api.analytics.enums.GoalPeriod;
import com.readingsanctuary.api.analytics.enums.GoalType;
import com.readingsanctuary.api.analytics.service.ActivitySessionService;
import com.readingsanctuary.api.analytics.service.AnalyticsService;
import com.readingsanctuary.api.analytics.service.ReadingGoalService;
import com.readingsanctuary.api.analytics.service.ReadingStreakService;
import com.readingsanctuary.api.analytics.service.ReadingWrapUpService;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class Step10ControllerValidationTest {

    @Mock
    private ActivitySessionService sessionService;

    @Mock
    private ReadingGoalService goalService;

    @Mock
    private AnalyticsService analyticsService;

    @Mock
    private ReadingStreakService streakService;

    @Mock
    private ReadingWrapUpService wrapUpService;

    private MockMvc sessionMockMvc;
    private MockMvc goalMockMvc;
    private MockMvc analyticsMockMvc;

    private final UUID testUserId = UUID.randomUUID();

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

        sessionMockMvc = MockMvcBuilders.standaloneSetup(new ActivitySessionController(sessionService))
                .setCustomArgumentResolvers(jwtResolver)
                .build();

        goalMockMvc = MockMvcBuilders.standaloneSetup(new ReadingGoalController(goalService))
                .setCustomArgumentResolvers(jwtResolver)
                .build();

        analyticsMockMvc = MockMvcBuilders.standaloneSetup(new AnalyticsController(analyticsService, streakService, wrapUpService))
                .setCustomArgumentResolvers(jwtResolver)
                .build();
    }

    @Test
    void startSession_validRequest_returns201() throws Exception {
        ActivitySessionResponse response = new ActivitySessionResponse(
                UUID.randomUUID(),
                testUserId,
                UUID.randomUUID(),
                UUID.randomUUID(),
                ActivityType.READING,
                OffsetDateTime.now(),
                null,
                OffsetDateTime.now(),
                0,
                0.0,
                0.0,
                0,
                true,
                OffsetDateTime.now(),
                OffsetDateTime.now()
        );

        when(sessionService.startSession(eq(testUserId), any())).thenReturn(response);

        sessionMockMvc.perform(post("/api/v1/analytics/sessions/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "activityType": "READING",
                                  "bookId": "%s"
                                }
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.activityType").value("READING"))
                .andExpect(jsonPath("$.isActive").value(true));
    }

    @Test
    void startSession_missingActivityType_returns400() throws Exception {
        sessionMockMvc.perform(post("/api/v1/analytics/sessions/start")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "bookId": "%s"
                                }
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createGoal_validRequest_returns201() throws Exception {
        ReadingGoalResponse response = new ReadingGoalResponse(
                UUID.randomUUID(),
                testUserId,
                GoalType.READING_MINUTES,
                30,
                GoalPeriod.DAILY,
                LocalDate.now(),
                LocalDate.now(),
                true,
                OffsetDateTime.now(),
                OffsetDateTime.now()
        );

        when(goalService.createGoal(eq(testUserId), any())).thenReturn(response);

        goalMockMvc.perform(post("/api/v1/analytics/goals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "goalType": "READING_MINUTES",
                                  "targetValue": 30,
                                  "periodType": "DAILY",
                                  "startDate": "2026-11-09",
                                  "endDate": "2026-11-09"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.targetValue").value(30))
                .andExpect(jsonPath("$.goalType").value("READING_MINUTES"));
    }

    @Test
    void createGoal_invalidTargetValue_returns400() throws Exception {
        goalMockMvc.perform(post("/api/v1/analytics/goals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "goalType": "READING_MINUTES",
                                  "targetValue": 0,
                                  "periodType": "DAILY",
                                  "startDate": "2026-11-09",
                                  "endDate": "2026-11-09"
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getOverview_returns200() throws Exception {
        AnalyticsOverviewResponse overview = new AnalyticsOverviewResponse(
                10L, 4L, 2L, 3L, 1L, 300L, 120L, 60L, 15L, 5, 4
        );

        when(analyticsService.getOverview(eq(testUserId), any(), any(), any())).thenReturn(overview);

        analyticsMockMvc.perform(get("/api/v1/analytics/overview"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalBooks").value(10))
                .andExpect(jsonPath("$.readingMinutes").value(300))
                .andExpect(jsonPath("$.currentStreak").value(5));
    }

    @Test
    void getStreaks_returns200() throws Exception {
        StreakResponse streak = new StreakResponse(
                7, 21, LocalDate.of(2026, 11, 2), LocalDate.of(2026, 11, 9), Collections.singletonList(LocalDate.of(2026, 11, 9))
        );

        when(streakService.calculateStreaks(eq(testUserId), any())).thenReturn(streak);

        analyticsMockMvc.perform(get("/api/v1/analytics/streaks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentStreak").value(7))
                .andExpect(jsonPath("$.longestStreak").value(21));
    }
}
