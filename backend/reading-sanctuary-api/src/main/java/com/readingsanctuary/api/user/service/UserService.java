package com.readingsanctuary.api.user.service;

import java.util.Locale;
import java.util.UUID;
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

    public static String deriveDisplayName(String email) {
        if (email == null || email.isBlank()) return "Reader";
        String prefix = email.split("@")[0].replaceAll("[._-]", " ");
        String[] words = prefix.split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (String w : words) {
            if (!w.isBlank()) {
                sb.append(Character.toUpperCase(w.charAt(0)))
                  .append(w.length() > 1 ? w.substring(1).toLowerCase() : "")
                  .append(" ");
            }
        }
        String result = sb.toString().trim();
        return result.isEmpty() ? "Reader" : result;
    }

    @Transactional
    public UserResponse registerUser(UserRegistrationRequest request) {
        String normalizedEmail = request.email().trim().toLowerCase(Locale.ROOT);
        if (userRepository.existsByEmailIgnoreCase(normalizedEmail)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                "An account with this email already exists");
        }
        String gender = request.gender() == null || request.gender().isBlank()
            ? null
            : request.gender().trim().toLowerCase(Locale.ROOT);
        String displayName = request.displayName();
        if (displayName == null || displayName.isBlank()) {
            displayName = deriveDisplayName(normalizedEmail);
        } else {
            displayName = displayName.trim();
        }
        String passwordToHash = request.password() != null ? request.password().trim() : "";
        User user = new User(normalizedEmail, passwordEncoder.encode(passwordToHash),
            displayName, null, null, gender);
        User saved = userRepository.save(user);
        return new UserResponse(saved.getId(), saved.getEmail(), saved.isActive(),
            saved.getCreatedAt(), saved.getDisplayName(), saved.getProfilePictureUrl(), saved.getGender());
    }

    @Transactional
    public UserResponse getUserById(UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        if (user.getDisplayName() == null || user.getDisplayName().isBlank()) {
            user.setDisplayName(deriveDisplayName(user.getEmail()));
            user = userRepository.save(user);
        }
        return new UserResponse(user.getId(), user.getEmail(), user.isActive(),
            user.getCreatedAt(), user.getDisplayName(), user.getProfilePictureUrl(), user.getGender());
    }

    @Transactional
    public UserResponse updateProfile(UUID userId, String displayName) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        if (displayName != null && !displayName.isBlank()) {
            user.setDisplayName(displayName.trim());
        }
        User saved = userRepository.save(user);
        return new UserResponse(saved.getId(), saved.getEmail(), saved.isActive(),
            saved.getCreatedAt(), saved.getDisplayName(), saved.getProfilePictureUrl(), saved.getGender());
    }

    @Transactional
    public UserResponse updateGender(UUID userId, String gender) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        user.setGender(gender.trim().toLowerCase(Locale.ROOT));
        User saved = userRepository.save(user);
        return new UserResponse(saved.getId(), saved.getEmail(), saved.isActive(),
            saved.getCreatedAt(), saved.getDisplayName(), saved.getProfilePictureUrl(), saved.getGender());
    }
}
