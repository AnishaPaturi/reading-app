package com.readingsanctuary.api.user.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.readingsanctuary.api.user.entity.User;

public interface UserRepository extends JpaRepository<User, UUID> {
    boolean existsByEmailIgnoreCase(String email);
    Optional<User> findByEmailIgnoreCase(String email);
    Optional<User> findFirstByDisplayNameIgnoreCase(String displayName);
    List<User> findAllByDisplayNameIgnoreCase(String displayName);
    Optional<User> findByDisplayNameIgnoreCase(String displayName);
    Optional<User> findByGoogleSub(String googleSub);

    @Query("SELECT u FROM User u WHERE " +
           "LOWER(u.email) = LOWER(:input) OR " +
           "LOWER(u.email) LIKE LOWER(CONCAT(:input, '@%')) OR " +
           "LOWER(u.displayName) = LOWER(:input) OR " +
           "LOWER(REPLACE(u.displayName, ' ', '')) = LOWER(REPLACE(:input, ' ', '')) OR " +
           "LOWER(u.displayName) LIKE LOWER(CONCAT(:input, ' %'))")
    List<User> findLoginCandidates(@Param("input") String input);
}
