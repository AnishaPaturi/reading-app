package com.readingsanctuary.api.analytics;

import java.time.LocalDate;
import java.util.List;
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

import com.readingsanctuary.api.analytics.dto.GoalProgressResponse;
import com.readingsanctuary.api.analytics.dto.ReadingGoalRequest;
import com.readingsanctuary.api.analytics.dto.ReadingGoalResponse;
import com.readingsanctuary.api.analytics.entity.ReadingGoal;
import com.readingsanctuary.api.analytics.enums.ActivityType;
import com.readingsanctuary.api.analytics.enums.GoalPeriod;
import com.readingsanctuary.api.analytics.enums.GoalType;
import com.readingsanctuary.api.analytics.repository.ReadingActivitySessionRepository;
import com.readingsanctuary.api.analytics.repository.ReadingGoalRepository;
import com.readingsanctuary.api.analytics.service.ReadingGoalService;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReadingGoalServiceTest {

    @Mock
    private ReadingGoalRepository goalRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private BookRepository bookRepository;

    @Mock
    private ReadingActivitySessionRepository sessionRepository;

    @InjectMocks
    private ReadingGoalService goalService;

    private UUID userId;
    private User user;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        user = new User("test@example.com", "hash");
        ReflectionTestUtils.setField(user, "id", userId);
    }

    @Test
    void createGoal_Success() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(goalRepository.findOverlappingActiveGoals(any(), any(), any(), any(), any(), any()))
                .thenReturn(List.of());

        when(goalRepository.save(any(ReadingGoal.class))).thenAnswer(inv -> {
            ReadingGoal g = inv.getArgument(0);
            ReflectionTestUtils.setField(g, "id", UUID.randomUUID());
            return g;
        });

        ReadingGoalRequest request = new ReadingGoalRequest(
                GoalType.BOOKS_COMPLETED,
                25,
                GoalPeriod.YEARLY,
                LocalDate.of(2026, 1, 1),
                LocalDate.of(2026, 12, 31)
        );

        ReadingGoalResponse response = goalService.createGoal(userId, request);

        assertThat(response).isNotNull();
        assertThat(response.goalType()).isEqualTo(GoalType.BOOKS_COMPLETED);
        assertThat(response.targetValue()).isEqualTo(25);
        assertThat(response.isActive()).isTrue();
    }

    @Test
    void createGoal_InvalidTargetValue_ThrowsBadRequest() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        ReadingGoalRequest request = new ReadingGoalRequest(
                GoalType.BOOKS_COMPLETED,
                0,
                GoalPeriod.YEARLY,
                LocalDate.of(2026, 1, 1),
                LocalDate.of(2026, 12, 31)
        );

        assertThatThrownBy(() -> goalService.createGoal(userId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void createGoal_EndDateBeforeStartDate_ThrowsBadRequest() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        ReadingGoalRequest request = new ReadingGoalRequest(
                GoalType.BOOKS_COMPLETED,
                10,
                GoalPeriod.YEARLY,
                LocalDate.of(2026, 12, 31),
                LocalDate.of(2026, 1, 1)
        );

        assertThatThrownBy(() -> goalService.createGoal(userId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void createGoal_OverlappingActiveGoal_ThrowsConflict() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        ReadingGoal existing = new ReadingGoal();
        when(goalRepository.findOverlappingActiveGoals(any(), any(), any(), any(), any(), any()))
                .thenReturn(List.of(existing));

        ReadingGoalRequest request = new ReadingGoalRequest(
                GoalType.BOOKS_COMPLETED,
                10,
                GoalPeriod.YEARLY,
                LocalDate.of(2026, 1, 1),
                LocalDate.of(2026, 12, 31)
        );

        assertThatThrownBy(() -> goalService.createGoal(userId, request))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.CONFLICT));
    }

    @Test
    void calculateProgress_BooksCompleted_Success() {
        UUID goalId = UUID.randomUUID();
        ReadingGoal goal = new ReadingGoal();
        ReflectionTestUtils.setField(goal, "id", goalId);
        goal.setUser(user);
        goal.setGoalType(GoalType.BOOKS_COMPLETED);
        goal.setTargetValue(50);
        goal.setPeriodType(GoalPeriod.YEARLY);
        goal.setStartDate(LocalDate.of(2026, 1, 1));
        goal.setEndDate(LocalDate.of(2026, 12, 31));

        when(goalRepository.findByIdAndUser_Id(goalId, userId)).thenReturn(Optional.of(goal));
        when(bookRepository.countCompletedBooksBetween(eq(userId), any(), any())).thenReturn(32L);

        GoalProgressResponse progress = goalService.calculateProgress(userId, goalId);

        assertThat(progress.goalId()).isEqualTo(goalId);
        assertThat(progress.targetValue()).isEqualTo(50);
        assertThat(progress.currentValue()).isEqualTo(32);
        assertThat(progress.percentage()).isEqualTo(64.0);
        assertThat(progress.remainingValue()).isEqualTo(18);
        assertThat(progress.completed()).isFalse();
    }

    @Test
    void calculateProgress_ReadingMinutes_Success() {
        UUID goalId = UUID.randomUUID();
        ReadingGoal goal = new ReadingGoal();
        ReflectionTestUtils.setField(goal, "id", goalId);
        goal.setUser(user);
        goal.setGoalType(GoalType.READING_MINUTES);
        goal.setTargetValue(100);
        goal.setPeriodType(GoalPeriod.DAILY);
        goal.setStartDate(LocalDate.of(2026, 11, 9));
        goal.setEndDate(LocalDate.of(2026, 11, 9));

        when(goalRepository.findByIdAndUser_Id(goalId, userId)).thenReturn(Optional.of(goal));
        // 7200 seconds = 120 minutes (exceeds target of 100)
        when(sessionRepository.sumDurationByActivityType(eq(userId), any(), any()))
                .thenReturn(List.of(new Object[]{ActivityType.READING, 7200L}));

        GoalProgressResponse progress = goalService.calculateProgress(userId, goalId);

        assertThat(progress.currentValue()).isEqualTo(120);
        assertThat(progress.percentage()).isEqualTo(100.0); // capped at 100% for display
        assertThat(progress.remainingValue()).isEqualTo(0);
        assertThat(progress.completed()).isTrue();
    }
}
