package com.readingsanctuary.api.auth;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.List;
import java.util.Locale;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
public class GoogleTokenVerifier {
    private final GoogleIdTokenVerifier verifier;

    public GoogleTokenVerifier(@Value("${app.google.client-id}") String clientId) {
        if (clientId == null || clientId.isBlank()) {
            throw new IllegalStateException("GOOGLE_CLIENT_ID must be configured");
        }
        this.verifier = new GoogleIdTokenVerifier.Builder(
            new NetHttpTransport(), GsonFactory.getDefaultInstance())
            .setAudience(List.of(clientId))
            .build();
    }

    public GoogleIdentity verify(String rawToken) {
        try {
            GoogleIdToken token = verifier.verify(rawToken);
            if (token == null) throw unauthorized();
            GoogleIdToken.Payload payload = token.getPayload();

            if (!Boolean.TRUE.equals(payload.getEmailVerified())) throw unauthorized();
            String subject = payload.getSubject();
            String email = payload.getEmail();
            if (subject == null || subject.isBlank() || email == null || email.isBlank()) {
                throw unauthorized();
            }

            String issuer = payload.getIssuer();
            if (!"accounts.google.com".equals(issuer)
                    && !"https://accounts.google.com".equals(issuer)) {
                throw unauthorized();
            }

            String name = stringClaim(payload, "name");
            String picture = stringClaim(payload, "picture");
            return new GoogleIdentity(subject, email.trim().toLowerCase(Locale.ROOT),
                name, picture);
        } catch (IOException | GeneralSecurityException ex) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                "Unable to verify Google identity token", ex);
        }
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
