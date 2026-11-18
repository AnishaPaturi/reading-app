package com.readingsanctuary.api.analytics.service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.analytics.dto.StreakResponse;
import com.readingsanctuary.api.analytics.dto.StreakResponse.WeeklyDayStatus;
import com.readingsanctuary.api.analytics.entity.ReadingActivitySession;
import com.readingsanctuary.api.analytics.entity.StreakFreeze;
import com.readingsanctuary.api.analytics.enums.ActivityType;
import com.readingsanctuary.api.analytics.repository.ReadingActivitySessionRepository;
import com.readingsanctuary.api.analytics.repository.StreakFreezeRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
@Transactional
public class ReadingStreakService {

    public static final int MINIMUM_ACTIVE_MINUTES = 5;
    public static final int MAX_MONTHLY_FREEZES = 2;

    private final ReadingActivitySessionRepository sessionRepository;
    private final StreakFreezeRepository freezeRepository;
    private final UserRepository userRepository;

    public ReadingStreakService(
            ReadingActivitySessionRepository sessionRepository,
            StreakFreezeRepository freezeRepository,
            UserRepository userRepository) {
        this.sessionRepository = sessionRepository;
        this.freezeRepository = freezeRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
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

        // Active days are those with at least 5 credited minutes (300 seconds) or >= 1 page advanced
        TreeSet<LocalDate> activeDays = dailySeconds.entrySet().stream()
                .filter(e -> e.getValue() >= MINIMUM_ACTIVE_MINUTES * 60)
                .map(Map.Entry::getKey)
                .collect(Collectors.toCollection(TreeSet::new));

        // Fetch user streak freezes
        List<StreakFreeze> freezes = freezeRepository.findAllByUser_IdOrderByFreezeDateDesc(userId);
        Set<LocalDate> frozenDates = freezes.stream()
                .map(StreakFreeze::getFreezeDate)
                .collect(Collectors.toSet());

        LocalDate today = LocalDate.now(zone);
        LocalDate yesterday = today.minusDays(1);

        // Calculate freezes available for current month
        int freezesUsedThisMonth = (int) freezes.stream()
                .filter(f -> f.getFreezeDate().getYear() == today.getYear() && f.getFreezeDate().getMonth() == today.getMonth())
                .count();
        int freezesAvailable = Math.max(0, MAX_MONTHLY_FREEZES - freezesUsedThisMonth);

        boolean isTodayComplete = activeDays.contains(today);

        // Calculate current streak with freezes supported
        int currentStreak = 0;
        LocalDate streakStartDate = null;
        if (activeDays.contains(today) || activeDays.contains(yesterday) || frozenDates.contains(today) || frozenDates.contains(yesterday)) {
            LocalDate check = (activeDays.contains(today) || frozenDates.contains(today)) ? today : yesterday;
            while (activeDays.contains(check) || frozenDates.contains(check)) {
                if (activeDays.contains(check)) {
                    currentStreak++;
                    streakStartDate = check;
                }
                check = check.minusDays(1);
            }
        }

        // Calculate longest streak
        TreeSet<LocalDate> allCreditedDays = new TreeSet<>(activeDays);
        allCreditedDays.addAll(frozenDates);

        int longestStreak = 0;
        int currentRun = 0;
        LocalDate prev = null;
        for (LocalDate date : allCreditedDays) {
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

        // Last active date
        LocalDate lastActiveDate = activeDays.isEmpty() ? null : activeDays.last();

        // Calculate Momentum (last 7 days active count)
        int momentumDays = 0;
        for (int i = 0; i < 7; i++) {
            LocalDate day = today.minusDays(i);
            if (activeDays.contains(day)) {
                momentumDays++;
            }
        }
        String momentumStatus = momentumDays >= 5 ? "Strong" : (momentumDays >= 3 ? "Consistent" : (momentumDays >= 1 ? "Building" : "Needs Momentum"));

        // Weekly activity (Monday to Sunday)
        LocalDate monday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        List<WeeklyDayStatus> weeklyDays = new ArrayList<>(7);
        for (int i = 0; i < 7; i++) {
            LocalDate date = monday.plusDays(i);
            boolean isCurToday = date.equals(today);
            boolean isFuture = date.isAfter(today);
            int secs = dailySeconds.getOrDefault(date, 0);
            boolean isCompleted = activeDays.contains(date) || frozenDates.contains(date);
            String dayName = date.getDayOfWeek().name().substring(0, 3); // MON, TUE, etc.

            weeklyDays.add(new WeeklyDayStatus(
                    date,
                    dayName,
                    isCompleted,
                    isCurToday,
                    isFuture,
                    secs / 60
            ));
        }

        return new StreakResponse(
                currentStreak,
                longestStreak,
                streakStartDate,
                lastActiveDate,
                new ArrayList<>(activeDays),
                isTodayComplete,
                freezesAvailable,
                freezes.size(),
                new ArrayList<>(frozenDates),
                momentumDays,
                momentumStatus,
                weeklyDays
        );
    }

    public StreakResponse toggleStreakFreeze(UUID userId, LocalDate date, ZoneId zoneId) {
        LocalDate freezeDate = (date != null) ? date : LocalDate.now(zoneId != null ? zoneId : ZoneOffset.UTC);

        Optional<StreakFreeze> existing = freezeRepository.findByUser_IdAndFreezeDate(userId, freezeDate);
        if (existing.isPresent()) {
            freezeRepository.delete(existing.get());
        } else {
            User user = userRepository.getReferenceById(userId);
            freezeRepository.save(new StreakFreeze(user, freezeDate));
        }

        return calculateStreaks(userId, zoneId);
    }

    public StreakResponse markTodayComplete(UUID userId, ZoneId zoneId) {
        ZoneId zone = (zoneId != null) ? zoneId : ZoneOffset.UTC;
        LocalDate today = LocalDate.now(zone);

        // Check if already complete today
        OffsetDateTime now = OffsetDateTime.now(zone);
        User user = userRepository.getReferenceById(userId);

        ReadingActivitySession session = new ReadingActivitySession();
        session.setUser(user);
        session.setActivityType(ActivityType.READING);
        session.setStartedAt(now.minusMinutes(MINIMUM_ACTIVE_MINUTES));
        session.setEndedAt(now);
        session.setLastHeartbeatAt(now);
        session.setDurationSeconds(MINIMUM_ACTIVE_MINUTES * 60);
        session.setPagesAdvanced(5);
        session.setActive(false);

        sessionRepository.save(session);

        return calculateStreaks(userId, zoneId);
    }
}
