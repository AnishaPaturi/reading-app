package com.readingsanctuary.api.auth;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtEncoder jwtEncoder;

    private static final long TOKEN_EXPIRATION_MINUTES = 15;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtEncoder jwtEncoder) {

        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtEncoder = jwtEncoder;
    }

    public LoginResponse login(LoginRequest request) {

        // Normalize the email before searching.
        String email = request.email().trim().toLowerCase();

        // Find the user.
        User user = userRepository.findByEmailIgnoreCase(email)
            .orElseThrow(() -> new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Invalid email or password"
            ));

        // Check whether the account is active.
        if (!user.isActive()) {
            throw new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Invalid email or password"
            );
        }

        // Verify the submitted password against the BCrypt hash.
        if (!passwordEncoder.matches(
                request.password(),
                user.getPasswordHash())) {

            throw new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Invalid email or password"
            );
        }

        // Generate JWT timestamps.
        Instant issuedAt = Instant.now();
        Instant expiresAt = issuedAt.plus(
            TOKEN_EXPIRATION_MINUTES,
            ChronoUnit.MINUTES
        );

        // Build JWT claims.
        JwtClaimsSet claims = JwtClaimsSet.builder()
            .issuer("reading-sanctuary-api")
            .issuedAt(issuedAt)
            .expiresAt(expiresAt)
            .subject(user.getId().toString())
            .claim("email", user.getEmail())
            .build();

        // Sign the token using HS256.
        JwsHeader header = JwsHeader
            .with(MacAlgorithm.HS256)
            .build();

        String token = jwtEncoder.encode(
            JwtEncoderParameters.from(header, claims)
        ).getTokenValue();

        // Return the token and basic user information.
        return new LoginResponse(
            token,
            "Bearer",
            TOKEN_EXPIRATION_MINUTES * 60,
            user.getId(),
            user.getEmail()
        );
    }
}
