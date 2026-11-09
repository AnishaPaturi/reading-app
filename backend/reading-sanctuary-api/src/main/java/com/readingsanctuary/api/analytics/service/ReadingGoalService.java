package com.readingsanctuary.api.analytics.service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.analytics.dto.GoalProgressResponse;
import com.readingsanctuary.api.analytics.dto.ReadingGoalRequest;
import com.readingsanctuary.api.analytics.dto.ReadingGoalResponse;
import com.readingsanctuary.api.analytics.entity.ReadingGoal;
import com.readingsanctuary.api.analytics.enums.ActivityType;
import com.readingsanctuary.api.analytics.enums.GoalType;
import com.readingsanctuary.api.analytics.repository.ReadingActivitySessionRepository;
import com.readingsanctuary.api.analytics.repository.ReadingGoalRepository;
import com.readingsanctuary.api.book.repository.BookRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
@Transactional
public class ReadingGoalService {

    private final ReadingGoalRepository goalRepository;
    private final UserRepository userRepository;
    private final BookRepository bookRepository;
    private final ReadingActivitySessionRepository sessionRepository;

    public ReadingGoalService(
            ReadingGoalRepository goalRepository,
            UserRepository userRepository,
            BookRepository bookRepository,
            ReadingActivitySessionRepository sessionRepository) {
        this.goalRepository = goalRepository;
        this.userRepository = userRepository;
        this.bookRepository = bookRepository;
        this.sessionRepository = sessionRepository;
    }

    public ReadingGoalResponse createGoal(UUID userId, ReadingGoalRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        validateGoalRequest(request);

        // Check for overlapping active goal with same type and period
        List<ReadingGoal> overlapping = goalRepository.findOverlappingActiveGoals(
                userId, request.goalType(), request.periodType(), request.startDate(), request.endDate(), null);
        if (!overlapping.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "An active goal of type " + request.goalType() + " for period " + request.periodType() + " already overlaps with this date range"
            );
        }

        ReadingGoal goal = new ReadingGoal();
        goal.setUser(user);
        goal.setGoalType(request.goalType());
        goal.setTargetValue(request.targetValue());
        goal.setPeriodType(request.periodType());
        goal.setStartDate(request.startDate());
        goal.setEndDate(request.endDate());
        goal.setActive(true);

        ReadingGoal saved = goalRepository.save(goal);
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<ReadingGoalResponse> getGoals(UUID userId) {
        return goalRepository.findAllByUser_IdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public ReadingGoalResponse getGoal(UUID userId, UUID goalId) {
        ReadingGoal goal = goalRepository.findByIdAndUser_Id(goalId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Goal not found"));
        return toResponse(goal);
    }

    public ReadingGoalResponse updateGoal(UUID userId, UUID goalId, ReadingGoalRequest request) {
        ReadingGoal goal = goalRepository.findByIdAndUser_Id(goalId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Goal not found"));

        validateGoalRequest(request);

        List<ReadingGoal> overlapping = goalRepository.findOverlappingActiveGoals(
                userId, request.goalType(), request.periodType(), request.startDate(), request.endDate(), goalId);
        if (!overlapping.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "An active goal of type " + request.goalType() + " for period " + request.periodType() + " already overlaps with this date range"
            );
        }

        goal.setGoalType(request.goalType());
        goal.setTargetValue(request.targetValue());
        goal.setPeriodType(request.periodType());
        goal.setStartDate(request.startDate());
        goal.setEndDate(request.endDate());

        ReadingGoal saved = goalRepository.save(goal);
        return toResponse(saved);
    }

    public void deleteGoal(UUID userId, UUID goalId) {
        ReadingGoal goal = goalRepository.findByIdAndUser_Id(goalId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Goal not found"));
        goalRepository.delete(goal);
    }

    @Transactional(readOnly = true)
    public GoalProgressResponse calculateProgress(UUID userId, UUID goalId) {
        ReadingGoal goal = goalRepository.findByIdAndUser_Id(goalId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Goal not found"));

        LocalDate start = goal.getStartDate();
        LocalDate end = goal.getEndDate();
        if (end == null) {
            end = switch (goal.getPeriodType()) {
                case DAILY -> start;
                case MONTHLY -> start.withDayOfMonth(start.lengthOfMonth());
                case YEARLY -> start.withDayOfYear(start.lengthOfYear());
            };
        }

        OffsetDateTime startOffset = start.atStartOfDay().atOffset(ZoneOffset.UTC);
        OffsetDateTime endOffset = end.plusDays(1).atStartOfDay().atOffset(ZoneOffset.UTC).minusNanos(1);

        int currentValue = 0;
        switch (goal.getGoalType()) {
            case BOOKS_COMPLETED -> {
                currentValue = (int) bookRepository.countCompletedBooksBetween(userId, start, end);
            }
            case READING_MINUTES -> {
                List<Object[]> rows = sessionRepository.sumDurationByActivityType(userId, startOffset, endOffset);
                for (Object[] row : rows) {
                    if (row[0] == ActivityType.READING) {
                        currentValue = ((Number) row[1]).intValue() / 60;
                    }
                }
            }
            case PAGES_READ -> {
                currentValue = sessionRepository.sumPagesAdvanced(userId, startOffset, endOffset);
            }
            case LISTENING_MINUTES -> {
                List<Object[]> rows = sessionRepository.sumDurationByActivityType(userId, startOffset, endOffset);
                int listeningSeconds = 0;
                for (Object[] row : rows) {
                    ActivityType type = (ActivityType) row[0];
                    if (type == ActivityType.AUDIOBOOK || type == ActivityType.TTS) {
                        listeningSeconds += ((Number) row[1]).intValue();
                    }
                }
                currentValue = listeningSeconds / 60;
            }
        }

        int targetValue = goal.getTargetValue();
        double percentage = targetValue > 0 ? ((double) currentValue / targetValue) * 100.0 : 0.0;
        double displayPercentage = Math.min(percentage, 100.0);
        int remainingValue = Math.max(0, targetValue - currentValue);
        boolean completed = currentValue >= targetValue;

        return new GoalProgressResponse(
                goal.getId(),
                goal.getGoalType(),
                targetValue,
                currentValue,
                Math.round(displayPercentage * 100.0) / 100.0,
                remainingValue,
                completed
        );
    }

    private void validateGoalRequest(ReadingGoalRequest request) {
        if (request.targetValue() <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Target value must be greater than zero");
        }
        if (request.endDate() != null && request.endDate().isBefore(request.startDate())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "End date cannot be before start date");
        }
    }

    public ReadingGoalResponse toResponse(ReadingGoal g) {
        return new ReadingGoalResponse(
                g.getId(),
                g.getUser().getId(),
                g.getGoalType(),
                g.getTargetValue(),
                g.getPeriodType(),
                g.getStartDate(),
                g.getEndDate(),
                g.isActive(),
                g.getCreatedAt(),
                g.getUpdatedAt()
        );
    }
}
