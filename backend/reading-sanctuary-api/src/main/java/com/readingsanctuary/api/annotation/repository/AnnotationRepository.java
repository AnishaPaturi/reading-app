package com.readingsanctuary.api.annotation.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.readingsanctuary.api.annotation.entity.Annotation;
import com.readingsanctuary.api.annotation.entity.AnnotationType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AnnotationRepository extends JpaRepository<Annotation, UUID> {

    List<Annotation> findByUserIdAndBookFileIdOrderByCreatedAtAsc(UUID userId, UUID bookFileId);

    List<Annotation> findByUserIdAndBookIdOrderByCreatedAtAsc(UUID userId, UUID bookId);

    List<Annotation> findByUserIdAndTypeOrderByCreatedAtDesc(UUID userId, AnnotationType type);

    List<Annotation> findByUserIdAndBookIdAndTypeOrderByCreatedAtDesc(UUID userId, UUID bookId, AnnotationType type);

    Optional<Annotation> findByIdAndUserId(UUID id, UUID userId);
}
