package com.readingsanctuary.api.collection.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.readingsanctuary.api.collection.entity.BookCollection;

public interface BookCollectionRepository
        extends JpaRepository<BookCollection, UUID> {

    List<BookCollection> findAllByUser_Id(UUID userId);

    Optional<BookCollection> findByIdAndUser_Id(
            UUID collectionId, UUID userId);

    @Query("""
        SELECT COUNT(c) > 0
        FROM BookCollection c
        WHERE c.user.id = :userId
          AND LOWER(c.name) = LOWER(:name)
          AND (
              (:parentId IS NULL AND c.parent IS NULL)
              OR c.parent.id = :parentId
          )
    """)
    boolean existsByUserAndNameAndParent(
            @Param("userId") UUID userId,
            @Param("name") String name,
            @Param("parentId") UUID parentId
    );
}
