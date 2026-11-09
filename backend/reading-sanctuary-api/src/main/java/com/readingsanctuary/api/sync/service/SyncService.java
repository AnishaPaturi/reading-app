package com.readingsanctuary.api.sync.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.readingsanctuary.api.sync.dto.*;
import com.readingsanctuary.api.sync.entity.SyncChange;
import com.readingsanctuary.api.sync.entity.SyncProcessedChange;
import com.readingsanctuary.api.sync.repository.SyncChangeRepository;
import com.readingsanctuary.api.sync.repository.SyncProcessedChangeRepository;

@Service
@Transactional
public class SyncService {

    private static final int DEFAULT_PULL_LIMIT = 100;
    private static final int MAX_PULL_LIMIT = 500;

    private final DeviceService deviceService;
    private final SyncChangeRepository changeRepository;
    private final SyncProcessedChangeRepository processedChangeRepository;
    private final SyncChangePublisher changePublisher;
    private final SyncConflictResolver conflictResolver;

    public SyncService(
            DeviceService deviceService,
            SyncChangeRepository changeRepository,
            SyncProcessedChangeRepository processedChangeRepository,
            SyncChangePublisher changePublisher,
            SyncConflictResolver conflictResolver) {
        this.deviceService = deviceService;
        this.changeRepository = changeRepository;
        this.processedChangeRepository = processedChangeRepository;
        this.changePublisher = changePublisher;
        this.conflictResolver = conflictResolver;
    }

    @Transactional(readOnly = true)
    public SyncPullResponse pull(UUID userId, UUID deviceId, long cursor, Integer limit) {
        deviceService.validateActiveDevice(userId, deviceId);

        int pageSize = (limit != null && limit > 0) ? Math.min(limit, MAX_PULL_LIMIT) : DEFAULT_PULL_LIMIT;
        List<SyncChange> changes = changeRepository.findByUserIdAndCursorGreaterThanOrderByCursorAsc(
                userId, cursor, PageRequest.of(0, pageSize)
        );

        long nextCursor = cursor;
        if (!changes.isEmpty()) {
            nextCursor = changes.get(changes.size() - 1).getCursor();
        }

        long remaining = changeRepository.countByUserIdAndCursorGreaterThan(userId, nextCursor);
        boolean hasMore = remaining > 0;

        List<SyncChangeDto> dtos = changes.stream()
                .map(this::toDto)
                .toList();

        return new SyncPullResponse(nextCursor, hasMore, dtos);
    }

    public SyncPushResponse push(UUID userId, SyncPushRequest request) {
        deviceService.validateActiveDevice(userId, request.deviceId());

        List<String> accepted = new ArrayList<>();
        List<SyncConflictDto> conflicts = new ArrayList<>();
        List<String> rejected = new ArrayList<>();

        for (SyncChangeDto change : request.changes()) {
            String clientChangeId = change.clientChangeId();

            // 1. Idempotency Check
            if (clientChangeId != null && processedChangeRepository.existsByClientChangeIdAndUserId(clientChangeId, userId)) {
                accepted.add(clientChangeId);
                continue;
            }

            // 2. Look up latest server change for this entity
            List<SyncChange> latest = changeRepository.findLatestChange(
                    userId, change.entityType(), change.entityId(), PageRequest.of(0, 1)
            );
            Optional<SyncChange> latestServerChange = latest.isEmpty() ? Optional.empty() : Optional.of(latest.get(0));

            // 3. Conflict Resolution
            SyncConflictResolver.ResolutionResult result = conflictResolver.resolve(change, latestServerChange);

            if (result.decision() == SyncConflictResolver.ConflictDecision.ACCEPT) {
                long newVersion = (latestServerChange.map(SyncChange::getEntityVersion).orElse(0L)) + 1L;

                changePublisher.publishChange(
                        userId,
                        change.entityType(),
                        change.entityId(),
                        change.operation(),
                        newVersion,
                        change.payload()
                );

                if (clientChangeId != null) {
                    processedChangeRepository.save(new SyncProcessedChange(clientChangeId, userId, request.deviceId()));
                    accepted.add(clientChangeId);
                }
            } else if (result.decision() == SyncConflictResolver.ConflictDecision.CONFLICT) {
                conflicts.add(result.conflict());
            } else {
                rejected.add(clientChangeId != null ? clientChangeId : change.entityId());
            }
        }

        long serverCursor = changeRepository.findMaxCursorByUserId(userId).orElse(0L);
        return new SyncPushResponse(accepted, conflicts, rejected, serverCursor);
    }

    public void acknowledge(UUID userId, SyncAcknowledgeRequest request) {
        long serverCursor = changeRepository.findMaxCursorByUserId(userId).orElse(0L);
        if (request.cursor() > serverCursor) {
            throw new IllegalArgumentException("Cannot acknowledge cursor ahead of server cursor: " + request.cursor());
        }

        deviceService.updateCursor(userId, request.deviceId(), request.cursor());
    }

    private SyncChangeDto toDto(SyncChange change) {
        return new SyncChangeDto(
                change.getCursor(),
                null,
                change.getEntityType(),
                change.getEntityId(),
                change.getOperation(),
                change.getEntityVersion(),
                null,
                change.getPayload(),
                change.getChangedAt()
        );
    }
}
