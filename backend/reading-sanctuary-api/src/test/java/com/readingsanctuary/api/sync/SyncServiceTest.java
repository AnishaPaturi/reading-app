package com.readingsanctuary.api.sync;

import java.time.OffsetDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;
import org.springframework.test.util.ReflectionTestUtils;

import com.readingsanctuary.api.sync.dto.*;
import com.readingsanctuary.api.sync.entity.SyncChange;
import com.readingsanctuary.api.sync.entity.SyncDevice;
import com.readingsanctuary.api.sync.repository.SyncChangeRepository;
import com.readingsanctuary.api.sync.repository.SyncProcessedChangeRepository;
import com.readingsanctuary.api.sync.service.DeviceService;
import com.readingsanctuary.api.sync.service.SyncChangePublisher;
import com.readingsanctuary.api.sync.service.SyncConflictResolver;
import com.readingsanctuary.api.sync.service.SyncService;
import com.readingsanctuary.api.user.entity.User;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SyncServiceTest {

    @Mock
    private DeviceService deviceService;

    @Mock
    private SyncChangeRepository changeRepository;

    @Mock
    private SyncProcessedChangeRepository processedChangeRepository;

    @Mock
    private SyncChangePublisher changePublisher;

    private SyncConflictResolver conflictResolver;
    private SyncService syncService;

    private UUID userId;
    private UUID deviceId;
    private SyncDevice mockDevice;

    @BeforeEach
    void setUp() {
        conflictResolver = new SyncConflictResolver();
        syncService = new SyncService(
                deviceService,
                changeRepository,
                processedChangeRepository,
                changePublisher,
                conflictResolver
        );

        userId = UUID.randomUUID();
        deviceId = UUID.randomUUID();

        User user = new User("reader@sanctuary.com", "hash");
        ReflectionTestUtils.setField(user, "id", userId);

        mockDevice = new SyncDevice();
        ReflectionTestUtils.setField(mockDevice, "id", deviceId);
        mockDevice.setUser(user);
        mockDevice.setActive(true);
    }

    @Test
    void pull_returnsChangesAndCursor() {
        when(deviceService.validateActiveDevice(userId, deviceId)).thenReturn(mockDevice);

        SyncChange change1 = new SyncChange();
        change1.setCursor(101L);
        change1.setEntityType("BOOKMARK");
        change1.setEntityId("b-1");
        change1.setOperation("CREATE");
        change1.setEntityVersion(1L);
        change1.setChangedAt(OffsetDateTime.now());

        when(changeRepository.findByUserIdAndCursorGreaterThanOrderByCursorAsc(eq(userId), eq(100L), any(Pageable.class)))
                .thenReturn(List.of(change1));
        when(changeRepository.countByUserIdAndCursorGreaterThan(userId, 101L)).thenReturn(0L);

        SyncPullResponse response = syncService.pull(userId, deviceId, 100L, 50);

        assertThat(response).isNotNull();
        assertThat(response.nextCursor()).isEqualTo(101L);
        assertThat(response.hasMore()).isFalse();
        assertThat(response.changes()).hasSize(1);
        assertThat(response.changes().get(0).entityId()).isEqualTo("b-1");
    }

    @Test
    void push_idempotency_ignoresDuplicateChanges() {
        when(deviceService.validateActiveDevice(userId, deviceId)).thenReturn(mockDevice);
        String clientChangeId = "client-uuid-123";

        when(processedChangeRepository.existsByClientChangeIdAndUserId(clientChangeId, userId)).thenReturn(true);

        SyncChangeDto changeDto = new SyncChangeDto(
                null,
                clientChangeId,
                "BOOKMARK",
                "bm-1",
                "CREATE",
                1L,
                0L,
                "{}",
                OffsetDateTime.now()
        );

        SyncPushRequest request = new SyncPushRequest(deviceId, List.of(changeDto));
        SyncPushResponse response = syncService.push(userId, request);

        assertThat(response.accepted()).contains(clientChangeId);
        assertThat(response.conflicts()).isEmpty();
        verifyNoInteractions(changePublisher);
    }

    @Test
    void push_readingPosition_alwaysAccepted() {
        when(deviceService.validateActiveDevice(userId, deviceId)).thenReturn(mockDevice);
        String clientChangeId = "pos-change-1";

        when(processedChangeRepository.existsByClientChangeIdAndUserId(clientChangeId, userId)).thenReturn(false);
        when(changeRepository.findLatestChange(eq(userId), eq("READING_POSITION"), eq("pos-1"), any(Pageable.class)))
                .thenReturn(Collections.emptyList());

        SyncChangeDto changeDto = new SyncChangeDto(
                null,
                clientChangeId,
                "READING_POSITION",
                "pos-1",
                "UPDATE",
                1L,
                0L,
                "{\"pageNumber\":45}",
                OffsetDateTime.now()
        );

        SyncPushRequest request = new SyncPushRequest(deviceId, List.of(changeDto));
        SyncPushResponse response = syncService.push(userId, request);

        assertThat(response.accepted()).contains(clientChangeId);
        verify(changePublisher).publishChange(eq(userId), eq("READING_POSITION"), eq("pos-1"), eq("UPDATE"), eq(1L), any());
        verify(processedChangeRepository).save(any());
    }

    @Test
    void push_note_detectsVersionConflict() {
        when(deviceService.validateActiveDevice(userId, deviceId)).thenReturn(mockDevice);
        String clientChangeId = "note-change-1";

        when(processedChangeRepository.existsByClientChangeIdAndUserId(clientChangeId, userId)).thenReturn(false);

        SyncChange serverChange = new SyncChange();
        serverChange.setEntityVersion(5L);
        serverChange.setOperation("UPDATE");
        serverChange.setPayload("{\"title\":\"Updated on server\"}");

        when(changeRepository.findLatestChange(eq(userId), eq("BOOK_NOTE"), eq("note-1"), any(Pageable.class)))
                .thenReturn(List.of(serverChange));

        // Client change based on outdated version 3
        SyncChangeDto changeDto = new SyncChangeDto(
                null,
                clientChangeId,
                "BOOK_NOTE",
                "note-1",
                "UPDATE",
                4L,
                3L,
                "{\"title\":\"Edited offline\"}",
                OffsetDateTime.now()
        );

        SyncPushRequest request = new SyncPushRequest(deviceId, List.of(changeDto));
        SyncPushResponse response = syncService.push(userId, request);

        assertThat(response.conflicts()).hasSize(1);
        assertThat(response.conflicts().get(0).reason()).isEqualTo("VERSION_CONFLICT");
        assertThat(response.conflicts().get(0).serverVersion()).isEqualTo(5L);
        verifyNoInteractions(changePublisher);
    }
}
