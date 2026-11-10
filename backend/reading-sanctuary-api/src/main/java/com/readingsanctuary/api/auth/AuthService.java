package com.readingsanctuary.api.auth;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
public class AuthService {
    private static final long TOKEN_EXPIRATION_MINUTES = 15;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtEncoder jwtEncoder;
    private final GoogleTokenVerifier googleTokenVerifier;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       JwtEncoder jwtEncoder, GoogleTokenVerifier googleTokenVerifier) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtEncoder = jwtEncoder;
        this.googleTokenVerifier = googleTokenVerifier;
    }

    public LoginResponse login(LoginRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        User user = userRepository.findByEmailIgnoreCase(email)
            .orElseThrow(() -> unauthorized("Invalid email or password"));
        if (!user.isActive() || user.getPasswordHash() == null
                || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw unauthorized("Invalid email or password");
        }
        return createLoginResponse(user);
    }

    @Transactional
    public LoginResponse loginWithGoogle(String idToken) {
        GoogleTokenVerifier.GoogleIdentity identity = googleTokenVerifier.verify(idToken);
        User user = userRepository.findByGoogleSub(identity.subject()).orElseGet(() -> {
            User existing = userRepository.findByEmailIgnoreCase(identity.email()).orElse(null);
            if (existing != null) {
                if (!existing.isActive()) throw unauthorized("This account is disabled");
                if (existing.getGoogleSub() != null
                        && !existing.getGoogleSub().equals(identity.subject())) {
                    throw unauthorized("This Google account cannot be linked to this user");
                }
                existing.setGoogleSub(identity.subject());
                if (existing.getDisplayName() == null || existing.getDisplayName().isBlank())
                    existing.setDisplayName(identity.name());
                if (existing.getProfilePictureUrl() == null)
                    existing.setProfilePictureUrl(identity.pictureUrl());
                return userRepository.save(existing);
            }
            return userRepository.save(new User(identity.email(), null, identity.name(),
                identity.pictureUrl(), identity.subject()));
        });
        if (!user.isActive()) throw unauthorized("This account is disabled");
        return createLoginResponse(user);
    }

    private LoginResponse createLoginResponse(User user) {
        Instant issuedAt = Instant.now();
        Instant expiresAt = issuedAt.plus(TOKEN_EXPIRATION_MINUTES, ChronoUnit.MINUTES);
        JwtClaimsSet claims = JwtClaimsSet.builder()
            .issuer("reading-sanctuary-api").issuedAt(issuedAt).expiresAt(expiresAt)
            .subject(user.getId().toString()).claim("email", user.getEmail()).build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        String token = jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
        return new LoginResponse(token, "Bearer", TOKEN_EXPIRATION_MINUTES * 60,
            user.getId(), user.getEmail(), user.getDisplayName(), user.getProfilePictureUrl());
    }

    private ResponseStatusException unauthorized(String message) {
        return new ResponseStatusException(HttpStatus.UNAUTHORIZED, message);
    }
}
