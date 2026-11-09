package com.readingsanctuary.api.analytics.service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.*;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.analytics.dto.StreakResponse;
import com.readingsanctuary.api.analytics.entity.ReadingActivitySession;
import com.readingsanctuary.api.analytics.repository.ReadingActivitySessionRepository;

@Service
@Transactional(readOnly = true)
public class ReadingStreakService {

    public static final int MINIMUM_ACTIVE_MINUTES = 5;

    private final ReadingActivitySessionRepository sessionRepository;

    public ReadingStreakService(ReadingActivitySessionRepository sessionRepository) {
        this.sessionRepository = sessionRepository;
    }

    public StreakResponse calculateStreaks(UUID userId, ZoneId zoneId) {
        ZoneId zone = (zoneId != null) ? zoneId : ZoneOffset.UTC;

        // Fetch all user sessions ordered by start date
        List<ReadingActivitySession> sessions = sessionRepository.findAllByUser_IdOrderByStartedAtDesc(userId);

        // Group credited duration by local calendar date
        Map<LocalDate, Integer> dailySeconds = new HashMap<>();
        for (ReadingActivitySession s : sessions) {
            LocalDate localDate = s.getStartedAt().atZoneSameInstant(zone).toLocalDate();
            dailySeconds.put(localDate, dailySeconds.getOrDefault(localDate, 0) + s.getDurationSeconds());
        }

        // Active days are those with at least 5 credited minutes (300 seconds)
        TreeSet<LocalDate> activeDays = dailySeconds.entrySet().stream()
                .filter(e -> e.getValue() >= MINIMUM_ACTIVE_MINUTES * 60)
                .map(Map.Entry::getKey)
                .collect(Collectors.toCollection(TreeSet::new));

        if (activeDays.isEmpty()) {
            return new StreakResponse(0, 0, null, null, Collections.emptyList());
        }

        LocalDate today = LocalDate.now(zone);
        LocalDate yesterday = today.minusDays(1);
        LocalDate lastActiveDate = activeDays.last();

        // Calculate current streak
        int currentStreak = 0;
        LocalDate streakStartDate = null;
        if (activeDays.contains(today) || activeDays.contains(yesterday)) {
            LocalDate check = activeDays.contains(today) ? today : yesterday;
            while (activeDays.contains(check)) {
                currentStreak++;
                streakStartDate = check;
                check = check.minusDays(1);
            }
        }

        // Calculate longest streak
        int longestStreak = 0;
        int currentRun = 0;
        LocalDate prev = null;
        for (LocalDate date : activeDays) {
            if (prev == null || date.equals(prev.plusDays(1))) {
                currentRun++;
            } else {
                currentRun = 1;
            }
            if (currentRun > longestStreak) {
                longestStreak = currentRun;
            }
            prev = date;
        }

        return new StreakResponse(
                currentStreak,
                longestStreak,
                streakStartDate,
                lastActiveDate,
                new ArrayList<>(activeDays)
        );
    }
}
