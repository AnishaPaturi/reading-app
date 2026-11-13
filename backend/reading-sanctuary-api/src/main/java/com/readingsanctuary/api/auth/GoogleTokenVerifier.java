package com.readingsanctuary.api.auth;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.GeneralSecurityException;
import java.time.Duration;
import java.util.List;
import java.util.Locale;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
public class GoogleTokenVerifier {
    private static final Logger log = LoggerFactory.getLogger(GoogleTokenVerifier.class);
    private final GoogleIdTokenVerifier verifier;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    public GoogleTokenVerifier(@Value("${app.google.client-id}") String clientId) {
        if (clientId == null || clientId.isBlank()) {
            throw new IllegalStateException("GOOGLE_CLIENT_ID must be configured");
        }
        this.verifier = new GoogleIdTokenVerifier.Builder(
            new NetHttpTransport(), GsonFactory.getDefaultInstance())
            .setAudience(List.of(clientId))
            .build();
        this.httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();
        this.objectMapper = new ObjectMapper();
    }

    public GoogleIdentity verify(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            throw unauthorized();
        }

        // 1. Attempt standard Google ID token verification (JWT)
        try {
            GoogleIdToken token = verifier.verify(rawToken);
            if (token != null) {
                GoogleIdToken.Payload payload = token.getPayload();
                if (Boolean.TRUE.equals(payload.getEmailVerified())) {
                    String subject = payload.getSubject();
                    String email = payload.getEmail();
                    if (subject != null && !subject.isBlank() && email != null && !email.isBlank()) {
                        String issuer = payload.getIssuer();
                        if ("accounts.google.com".equals(issuer)
                                || "https://accounts.google.com".equals(issuer)) {
                            String name = stringClaim(payload, "name");
                            String picture = stringClaim(payload, "picture");
                            return new GoogleIdentity(subject, email.trim().toLowerCase(Locale.ROOT),
                                name, picture);
                        }
                    }
                }
            }
        } catch (IOException | GeneralSecurityException ex) {
            log.debug("Token is not a valid Google ID token JWT, attempting userinfo fallback: {}", ex.getMessage());
        } catch (Exception ex) {
            log.debug("ID token verification exception, attempting userinfo fallback: {}", ex.getMessage());
        }

        // 2. Fallback: Query Google's userinfo endpoint (supports OAuth2 access tokens)
        try {
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://www.googleapis.com/oauth2/v3/userinfo"))
                .header("Authorization", "Bearer " + rawToken)
                .GET()
                .timeout(Duration.ofSeconds(10))
                .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                JsonNode json = objectMapper.readTree(response.body());
                boolean emailVerified = json.path("email_verified").asBoolean(false);
                String email = json.path("email").asText(null);
                String subject = json.path("sub").asText(null);
                if (emailVerified && email != null && !email.isBlank() && subject != null && !subject.isBlank()) {
                    String name = json.path("name").asText(null);
                    String picture = json.path("picture").asText(null);
                    return new GoogleIdentity(subject, email.trim().toLowerCase(Locale.ROOT),
                        name, picture);
                }
            } else {
                log.warn("Google userinfo returned status {}: {}", response.statusCode(), response.body());
            }
        } catch (Exception ex) {
            log.warn("Error verifying token with Google userinfo endpoint: {}", ex.getMessage());
        }

        throw unauthorized();
    }

    private static String stringClaim(GoogleIdToken.Payload payload, String key) {
        Object value = payload.get(key);
        return value instanceof String ? (String) value : null;
    }

    private static ResponseStatusException unauthorized() {
        return new ResponseStatusException(HttpStatus.UNAUTHORIZED,
            "Google identity token is invalid or its email is not verified");
    }

    public record GoogleIdentity(String subject, String email, String name,
                                 String pictureUrl) {}
}
