package com.readingsanctuary.api.analytics.controller;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.readingsanctuary.api.analytics.dto.*;
import com.readingsanctuary.api.analytics.service.AnalyticsService;
import com.readingsanctuary.api.analytics.service.ReadingStreakService;
import com.readingsanctuary.api.analytics.service.ReadingWrapUpService;

@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsController {

    private final AnalyticsService analyticsService;
    private final ReadingStreakService streakService;
    private final ReadingWrapUpService wrapUpService;

    public AnalyticsController(
            AnalyticsService analyticsService,
            ReadingStreakService streakService,
            ReadingWrapUpService wrapUpService) {
        this.analyticsService = analyticsService;
        this.streakService = streakService;
        this.wrapUpService = wrapUpService;
    }

    @GetMapping("/overview")
    public ResponseEntity<AnalyticsOverviewResponse> getOverview(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) LocalDate from,
            @RequestParam(required = false) LocalDate to,
            @RequestParam(required = false) String timezone) {

        UUID userId = UUID.fromString(jwt.getSubject());
        ZoneId zone = resolveZoneId(timezone);
        return ResponseEntity.ok(analyticsService.getOverview(userId, from, to, zone));
    }

    @GetMapping("/activity")
    public ResponseEntity<ActivitySummaryResponse> getActivity(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(defaultValue = "MONTH") String period,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) String timezone) {

        UUID userId = UUID.fromString(jwt.getSubject());
        ZoneId zone = resolveZoneId(timezone);
        return ResponseEntity.ok(analyticsService.getActivity(userId, period, year, month, zone));
    }

    @GetMapping("/streaks")
    public ResponseEntity<StreakResponse> getStreaks(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String timezone) {

        UUID userId = UUID.fromString(jwt.getSubject());
        ZoneId zone = resolveZoneId(timezone);
        return ResponseEntity.ok(streakService.calculateStreaks(userId, zone));
    }

    @GetMapping("/reading-pace")
    public ResponseEntity<ReadingPaceResponse> getReadingPace(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) LocalDate from,
            @RequestParam(required = false) LocalDate to) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(analyticsService.getReadingPace(userId, year, from, to));
    }

    @GetMapping("/books-completed")
    public ResponseEntity<BooksCompletedResponse> getBooksCompleted(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) Integer year) {

        UUID userId = UUID.fromString(jwt.getSubject());
        int targetYear = (year != null) ? year : LocalDate.now().getYear();
        return ResponseEntity.ok(analyticsService.getBooksCompleted(userId, targetYear));
    }

    @GetMapping("/genres")
    public ResponseEntity<GenreAnalyticsResponse> getGenres(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) Integer year) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(analyticsService.getGenres(userId, year));
    }

    @GetMapping("/authors")
    public ResponseEntity<AuthorAnalyticsResponse> getAuthors(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) Integer year) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(analyticsService.getAuthors(userId, year));
    }

    @GetMapping("/listening")
    public ResponseEntity<ListeningAnalyticsResponse> getListening(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) Integer year) {

        UUID userId = UUID.fromString(jwt.getSubject());
        return ResponseEntity.ok(analyticsService.getListening(userId, year));
    }

    @GetMapping("/wrap-up")
    public ResponseEntity<YearlyWrapUpResponse> getWrapUp(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) Integer year) {

        UUID userId = UUID.fromString(jwt.getSubject());
        int targetYear = (year != null) ? year : LocalDate.now().getYear();
        return ResponseEntity.ok(wrapUpService.generateWrapUp(userId, targetYear));
    }

    private ZoneId resolveZoneId(String timezone) {
        if (timezone != null && !timezone.isBlank()) {
            try {
                return ZoneId.of(timezone.trim());
            } catch (Exception ignored) {
            }
        }
        return ZoneId.of("UTC");
    }
}
