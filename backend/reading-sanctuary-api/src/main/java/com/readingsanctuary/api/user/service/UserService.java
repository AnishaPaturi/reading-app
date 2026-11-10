package com.readingsanctuary.api.user.service;

import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import com.readingsanctuary.api.user.dto.UserRegistrationRequest;
import com.readingsanctuary.api.user.dto.UserResponse;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public UserResponse registerUser(UserRegistrationRequest request) {
        String normalizedEmail = request.email().trim().toLowerCase(Locale.ROOT);
        if (userRepository.existsByEmailIgnoreCase(normalizedEmail)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                "An account with this email already exists");
        }
        User user = new User(normalizedEmail, passwordEncoder.encode(request.password()),
            request.displayName() == null ? null : request.displayName().trim(), null, null);
        User saved = userRepository.save(user);
        return new UserResponse(saved.getId(), saved.getEmail(), saved.isActive(),
            saved.getCreatedAt(), saved.getDisplayName(), saved.getProfilePictureUrl());
    }
}
