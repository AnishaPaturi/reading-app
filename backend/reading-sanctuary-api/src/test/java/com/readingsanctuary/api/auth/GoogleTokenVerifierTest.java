package com.readingsanctuary.api.auth;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GoogleTokenVerifierTest {

    @Test
    void constructor_RejectsBlankClientId() {
        assertThatThrownBy(() -> new GoogleTokenVerifier("   "))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("GOOGLE_CLIENT_ID");
    }

    @Test
    void verify_RejectsNullOrBlankTokenWithUnauthorized() {
        GoogleTokenVerifier verifier = new GoogleTokenVerifier("test-client-id.apps.googleusercontent.com");

        assertThatThrownBy(() -> verifier.verify(null))
            .isInstanceOf(ResponseStatusException.class)
            .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED));

        assertThatThrownBy(() -> verifier.verify("   "))
            .isInstanceOf(ResponseStatusException.class)
            .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED));
    }

    @Test
    void verify_RejectsMalformedOrInvalidTokenWithUnauthorized() {
        GoogleTokenVerifier verifier = new GoogleTokenVerifier("test-client-id.apps.googleusercontent.com");

        assertThatThrownBy(() -> verifier.verify("not.a.valid.google.jwt"))
            .isInstanceOf(ResponseStatusException.class)
            .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED));
    }
}
