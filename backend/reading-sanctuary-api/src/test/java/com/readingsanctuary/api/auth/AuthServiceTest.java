package com.readingsanctuary.api.auth;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import org.mockito.Mock;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtEncoder jwtEncoder;

    @Mock
    private GoogleTokenVerifier googleTokenVerifier;

    @Mock
    private Jwt jwt;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(userRepository, passwordEncoder, jwtEncoder, googleTokenVerifier);
    }

    @Test
    void loginWithEmail_Success_ReturnsGender() {
        User user = new User("reader@example.com", "encoded-pass", "Reader", null, null, "male");
        ReflectionTestUtils.setField(user, "id", UUID.randomUUID());
        when(userRepository.findByEmailIgnoreCase("reader@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("password123", "encoded-pass")).thenReturn(true);
        when(jwtEncoder.encode(any(JwtEncoderParameters.class))).thenReturn(jwt);
        when(jwt.getTokenValue()).thenReturn("test-token");

        LoginResponse response = authService.login(new LoginRequest("reader@example.com", "password123"));

        assertThat(response.accessToken()).isEqualTo("test-token");
        assertThat(response.email()).isEqualTo("reader@example.com");
        assertThat(response.displayName()).isEqualTo("Reader");
        assertThat(response.gender()).isEqualTo("male");
    }

    @Test
    void loginWithUsername_Success_ReturnsGender() {
        User user = new User("reader@example.com", "encoded-pass", "CoolReader", null, null, "female");
        ReflectionTestUtils.setField(user, "id", UUID.randomUUID());
        when(userRepository.findByEmailIgnoreCase("coolreader")).thenReturn(Optional.empty());
        when(userRepository.findFirstByDisplayNameIgnoreCase("CoolReader")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("password123", "encoded-pass")).thenReturn(true);
        when(jwtEncoder.encode(any(JwtEncoderParameters.class))).thenReturn(jwt);
        when(jwt.getTokenValue()).thenReturn("test-token");

        LoginResponse response = authService.login(new LoginRequest("CoolReader", "password123"));

        assertThat(response.accessToken()).isEqualTo("test-token");
        assertThat(response.email()).isEqualTo("reader@example.com");
        assertThat(response.displayName()).isEqualTo("CoolReader");
        assertThat(response.gender()).isEqualTo("female");
    }

    @Test
    void login_InvalidCredentials_ThrowsUnauthorized() {
        when(userRepository.findByEmailIgnoreCase("unknown@example.com")).thenReturn(Optional.empty());
        when(userRepository.findFirstByDisplayNameIgnoreCase("unknown@example.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(new LoginRequest("unknown@example.com", "wrongpass")))
            .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void loginWithMultipleCandidates_SelectsUserWithMatchingPassword() {
        User user1 = new User("user1@example.com", "hash1", "Reader", null, null, "male");
        ReflectionTestUtils.setField(user1, "id", UUID.randomUUID());
        User user2 = new User("user2@example.com", "hash2", "Reader", null, null, "female");
        ReflectionTestUtils.setField(user2, "id", UUID.randomUUID());

        when(userRepository.findLoginCandidates("Reader")).thenReturn(java.util.List.of(user1, user2));
        lenient().when(passwordEncoder.matches(anyString(), anyString())).thenReturn(false);
        lenient().when(passwordEncoder.matches("mypass2", "hash2")).thenReturn(true);
        when(jwtEncoder.encode(any(JwtEncoderParameters.class))).thenReturn(jwt);
        when(jwt.getTokenValue()).thenReturn("test-token-2");

        LoginResponse response = authService.login(new LoginRequest("Reader", "mypass2"));

        assertThat(response.accessToken()).isEqualTo("test-token-2");
        assertThat(response.email()).isEqualTo("user2@example.com");
        assertThat(response.displayName()).isEqualTo("Reader");
    }

    @Test
    void loginWithGoogleAccountWithoutPassword_GivesClearHelpfulMessage() {
        User googleUser = new User("google@example.com", null, "Google User", null, "google-sub-123", null);
        when(userRepository.findLoginCandidates("google@example.com")).thenReturn(java.util.List.of(googleUser));

        assertThatThrownBy(() -> authService.login(new LoginRequest("google@example.com", "anypass")))
            .isInstanceOf(ResponseStatusException.class)
            .hasMessageContaining("Google Sign-In");
    }
}
