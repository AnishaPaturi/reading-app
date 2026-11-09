package com.readingsanctuary.api.sync.service;

import java.util.Optional;

import org.springframework.stereotype.Component;

import com.readingsanctuary.api.sync.dto.SyncChangeDto;
import com.readingsanctuary.api.sync.dto.SyncConflictDto;
import com.readingsanctuary.api.sync.entity.SyncChange;

@Component
public class SyncConflictResolver {

    public enum ConflictDecision {
        ACCEPT,
        REJECT,
        CONFLICT
    }

    public record ResolutionResult(
            ConflictDecision decision,
            SyncConflictDto conflict
    ) {
        public static ResolutionResult accept() {
            return new ResolutionResult(ConflictDecision.ACCEPT, null);
        }

        public static ResolutionResult conflict(SyncConflictDto conflict) {
            return new ResolutionResult(ConflictDecision.CONFLICT, conflict);
        }

        public static ResolutionResult reject(String clientChangeId, String entityType, String entityId, String reason) {
            return new ResolutionResult(ConflictDecision.REJECT, new SyncConflictDto(
                    clientChangeId, entityType, entityId, reason, 0, null, reason
            ));
        }
    }

    public ResolutionResult resolve(SyncChangeDto incoming, Optional<SyncChange> latestServerChange) {
        if (latestServerChange.isEmpty()) {
            return ResolutionResult.accept();
        }

        SyncChange server = latestServerChange.get();

        // If server already deleted the entity, tombstone takes precedence
        if ("DELETE".equalsIgnoreCase(server.getOperation())) {
            if ("DELETE".equalsIgnoreCase(incoming.operation())) {
                return ResolutionResult.accept(); // Idempotent delete
            }
            return ResolutionResult.conflict(new SyncConflictDto(
                    incoming.clientChangeId(),
                    incoming.entityType(),
                    incoming.entityId(),
                    "ENTITY_DELETED_ON_SERVER",
                    server.getEntityVersion(),
                    server.getPayload(),
                    "The entity was deleted on another device."
            ));
        }

        String type = incoming.entityType().toUpperCase();

        // 1. Reading, Audiobook, and TTS positions: Most recent progress update wins
        if (type.contains("POSITION")) {
            return ResolutionResult.accept();
        }

        // 2. Bookmarks and Highlights: Merge by ID
        if (type.contains("BOOKMARK") || type.contains("HIGHLIGHT")) {
            return ResolutionResult.accept();
        }

        // 3. Activity Sessions: Idempotent session processing
        if (type.contains("SESSION")) {
            return ResolutionResult.accept();
        }

        // 4. Notes, Reviews, Book Details: Version check
        long incomingBase = incoming.baseVersion() != null ? incoming.baseVersion() : 0L;
        if (incomingBase < server.getEntityVersion()) {
            return ResolutionResult.conflict(new SyncConflictDto(
                    incoming.clientChangeId(),
                    incoming.entityType(),
                    incoming.entityId(),
                    "VERSION_CONFLICT",
                    server.getEntityVersion(),
                    server.getPayload(),
                    "Concurrent modification detected. Server has version " + server.getEntityVersion() +
                            ", client based on version " + incomingBase
            ));
        }

        return ResolutionResult.accept();
    }
}
