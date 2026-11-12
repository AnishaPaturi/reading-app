package com.readingsanctuary.api.user;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import static org.mockito.ArgumentMatchers.any;
import org.mockito.Mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.user.dto.UserRegistrationRequest;
import com.readingsanctuary.api.user.dto.UserResponse;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;
import com.readingsanctuary.api.user.service.UserService;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private UserService userService;

    @BeforeEach
    void setUp() {
        userService = new UserService(userRepository, passwordEncoder);
    }

    @Test
    void registerUser_Success_PersistsGender() {
        UserRegistrationRequest request = new UserRegistrationRequest(
            "newuser@example.com", "secretpass123", "New User", "male");

        when(userRepository.existsByEmailIgnoreCase("newuser@example.com")).thenReturn(false);
        when(passwordEncoder.encode("secretpass123")).thenReturn("encoded-secret");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            return u;
        });

        UserResponse response = userService.registerUser(request);

        assertThat(response.email()).isEqualTo("newuser@example.com");
        assertThat(response.displayName()).isEqualTo("New User");
        assertThat(response.gender()).isEqualTo("male");
        verify(userRepository).save(any(User.class));
    }

    @Test
    void registerUser_DuplicateEmail_ThrowsConflict() {
        UserRegistrationRequest request = new UserRegistrationRequest(
            "existing@example.com", "secretpass123", "Existing", "female");

        when(userRepository.existsByEmailIgnoreCase("existing@example.com")).thenReturn(true);

        assertThatThrownBy(() -> userService.registerUser(request))
            .isInstanceOf(ResponseStatusException.class);
    }
}
