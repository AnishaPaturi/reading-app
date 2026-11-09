package com.readingsanctuary.api.sync.service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import com.readingsanctuary.api.sync.entity.SyncChange;
import com.readingsanctuary.api.sync.repository.SyncChangeRepository;

@Service
public class SyncChangePublisher {

    private static final Logger log = LoggerFactory.getLogger(SyncChangePublisher.class);

    @PersistenceContext
    private EntityManager entityManager;

    private final SyncChangeRepository changeRepository;
    private final ObjectMapper objectMapper;

    public SyncChangePublisher(SyncChangeRepository changeRepository) {
        this(changeRepository, null);
    }

    @Autowired
    public SyncChangePublisher(SyncChangeRepository changeRepository, @Autowired(required = false) ObjectMapper objectMapper) {
        this.changeRepository = changeRepository;
        this.objectMapper = objectMapper != null ? objectMapper : new ObjectMapper().findAndRegisterModules();
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public SyncChange publishChange(
            UUID userId,
            String entityType,
            String entityId,
            String operation,
            long entityVersion,
            Object payload) {

        long nextCursor = allocateNextCursor(userId);

        String payloadJson = null;
        if (payload != null) {
            if (payload instanceof String str) {
                payloadJson = str;
            } else {
                try {
                    payloadJson = objectMapper.writeValueAsString(payload);
                } catch (Exception e) {
                    log.warn("Could not serialize sync payload for entity {}: {}", entityId, e.getMessage());
                    payloadJson = payload.toString();
                }
            }
        }

        SyncChange change = new SyncChange();
        change.setUserId(userId);
        change.setCursor(nextCursor);
        change.setEntityType(entityType);
        change.setEntityId(entityId);
        change.setOperation(operation);
        change.setEntityVersion(entityVersion);
        change.setPayload(payloadJson);
        change.setChangedAt(OffsetDateTime.now());

        return changeRepository.save(change);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public SyncChange publishCreate(UUID userId, String entityType, String entityId, long version, Object payload) {
        return publishChange(userId, entityType, entityId, "CREATE", version, payload);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public SyncChange publishUpdate(UUID userId, String entityType, String entityId, long version, Object payload) {
        return publishChange(userId, entityType, entityId, "UPDATE", version, payload);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public SyncChange publishDelete(UUID userId, String entityType, String entityId, long version) {
        return publishChange(userId, entityType, entityId, "DELETE", version, null);
    }

    private long allocateNextCursor(UUID userId) {
        // Atomic per-user monotonic sequence using sync_user_cursors row lock
        Query selectQuery = entityManager.createNativeQuery(
                "SELECT current_cursor FROM sync_user_cursors WHERE user_id = :userId FOR UPDATE");
        selectQuery.setParameter("userId", userId);
        List<?> rows = selectQuery.getResultList();

        long nextCursor;
        if (rows.isEmpty()) {
            nextCursor = 1L;
            entityManager.createNativeQuery(
                    "INSERT INTO sync_user_cursors (user_id, current_cursor) VALUES (:userId, 1)")
                    .setParameter("userId", userId)
                    .executeUpdate();
        } else {
            nextCursor = ((Number) rows.get(0)).longValue() + 1L;
            entityManager.createNativeQuery(
                    "UPDATE sync_user_cursors SET current_cursor = :nextCursor WHERE user_id = :userId")
                    .setParameter("nextCursor", nextCursor)
                    .setParameter("userId", userId)
                    .executeUpdate();
        }

        return nextCursor;
    }
}
