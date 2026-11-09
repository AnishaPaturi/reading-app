package com.readingsanctuary.api;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

import com.readingsanctuary.api.storage.controller.CloudStorageController;
import com.readingsanctuary.api.storage.dto.*;
import com.readingsanctuary.api.storage.enums.StorageProvider;
import com.readingsanctuary.api.storage.enums.UploadStatus;
import com.readingsanctuary.api.storage.service.CloudStorageService;
import com.readingsanctuary.api.storage.service.LocalStorageService;
import com.readingsanctuary.api.sync.controller.DeviceController;
import com.readingsanctuary.api.sync.controller.SyncController;
import com.readingsanctuary.api.sync.dto.*;
import com.readingsanctuary.api.sync.service.DeviceService;
import com.readingsanctuary.api.sync.service.SyncService;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class Step11ControllerValidationTest {

    @Mock
    private CloudStorageService cloudStorageService;

    @Mock
    private LocalStorageService localStorageService;

    @Mock
    private DeviceService deviceService;

    @Mock
    private SyncService syncService;

    private MockMvc storageMockMvc;
    private MockMvc deviceMockMvc;
    private MockMvc syncMockMvc;

    private final UUID testUserId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        HandlerMethodArgumentResolver jwtResolver = new HandlerMethodArgumentResolver() {
            @Override
            public boolean supportsParameter(MethodParameter parameter) {
                return parameter.hasParameterAnnotation(AuthenticationPrincipal.class);
            }

            @Override
            public Object resolveArgument(MethodParameter parameter,
                                          ModelAndViewContainer mavContainer,
                                          NativeWebRequest webRequest,
                                          WebDataBinderFactory binderFactory) {
                return Jwt.withTokenValue("mock-jwt-token")
                        .header("alg", "none")
                        .claim("sub", testUserId.toString())
                        .build();
            }
        };

        storageMockMvc = MockMvcBuilders.standaloneSetup(new CloudStorageController(cloudStorageService, localStorageService))
                .setCustomArgumentResolvers(jwtResolver)
                .build();

        deviceMockMvc = MockMvcBuilders.standaloneSetup(new DeviceController(deviceService))
                .setCustomArgumentResolvers(jwtResolver)
                .build();

        syncMockMvc = MockMvcBuilders.standaloneSetup(new SyncController(syncService))
                .setCustomArgumentResolvers(jwtResolver)
                .build();
    }

    @Test
    void requestUploadUrl_valid_returns201() throws Exception {
        UUID fileId = UUID.randomUUID();
        UploadUrlResponse response = new UploadUrlResponse(
                UUID.randomUUID(),
                fileId,
                "users/u/books/b/f.pdf",
                "https://s3.amazonaws.com/test-bucket/f.pdf?sig=123",
                900L
        );

        when(cloudStorageService.requestUploadUrl(eq(testUserId), any(UploadUrlRequest.class))).thenReturn(response);

        String json = """
                {
                    "bookId": "%s",
                    "fileName": "clean_code.pdf",
                    "contentType": "application/pdf",
                    "fileSize": 1048576,
                    "checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
                }
                """.formatted(UUID.randomUUID());

        storageMockMvc.perform(post("/api/v1/storage/upload-url")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.fileId").value(fileId.toString()))
                .andExpect(jsonPath("$.uploadUrl").value(response.uploadUrl()))
                .andExpect(jsonPath("$.expiresInSeconds").value(900));
    }

    @Test
    void completeUpload_valid_returns200() throws Exception {
        UUID fileId = UUID.randomUUID();
        StorageFileResponse response = new StorageFileResponse(
                fileId,
                UUID.randomUUID(),
                "clean_code.pdf",
                "PDF",
                1048576L,
                StorageProvider.LOCAL,
                UploadStatus.VERIFIED,
                "sha256",
                OffsetDateTime.now(),
                OffsetDateTime.now()
        );

        when(cloudStorageService.completeUpload(eq(testUserId), any(CompleteUploadRequest.class))).thenReturn(response);

        String json = """
                {
                    "fileId": "%s",
                    "checksum": "sha256",
                    "fileSizeBytes": 1048576
                }
                """.formatted(fileId);

        storageMockMvc.perform(post("/api/v1/storage/complete-upload")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.storageStatus").value("VERIFIED"));
    }

    @Test
    void getDownloadUrl_valid_returns200() throws Exception {
        UUID fileId = UUID.randomUUID();
        DownloadUrlResponse response = new DownloadUrlResponse(
                fileId,
                "https://s3.amazonaws.com/download.pdf",
                900L,
                "clean_code.pdf",
                "sha256"
        );

        when(cloudStorageService.generateDownloadUrl(eq(testUserId), eq(fileId))).thenReturn(response);

        storageMockMvc.perform(get("/api/v1/storage/files/{fileId}/download-url", fileId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fileId").value(fileId.toString()))
                .andExpect(jsonPath("$.downloadUrl").value(response.downloadUrl()));
    }

    @Test
    void registerDevice_valid_returns201() throws Exception {
        UUID deviceId = UUID.randomUUID();
        DeviceResponse response = new DeviceResponse(
                deviceId,
                "Pixel 7",
                "ANDROID",
                0L,
                OffsetDateTime.now(),
                true,
                OffsetDateTime.now()
        );

        when(deviceService.registerDevice(eq(testUserId), any(DeviceRegistrationRequest.class))).thenReturn(response);

        String json = """
                {
                    "deviceName": "Pixel 7",
                    "platform": "ANDROID"
                }
                """;

        deviceMockMvc.perform(post("/api/v1/sync/devices")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(deviceId.toString()))
                .andExpect(jsonPath("$.deviceName").value("Pixel 7"));
    }

    @Test
    void pull_valid_returns200() throws Exception {
        UUID deviceId = UUID.randomUUID();
        SyncPullResponse response = new SyncPullResponse(15L, false, List.of());

        when(syncService.pull(eq(testUserId), eq(deviceId), anyLong(), any())).thenReturn(response);

        syncMockMvc.perform(get("/api/v1/sync/pull")
                        .param("deviceId", deviceId.toString())
                        .param("cursor", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nextCursor").value(15))
                .andExpect(jsonPath("$.hasMore").value(false));
    }

    @Test
    void push_valid_returns200() throws Exception {
        UUID deviceId = UUID.randomUUID();
        SyncPushResponse response = new SyncPushResponse(List.of("c-1"), List.of(), List.of(), 10L);

        when(syncService.push(eq(testUserId), any(SyncPushRequest.class))).thenReturn(response);

        String json = """
                {
                    "deviceId": "%s",
                    "changes": [
                        {
                            "clientChangeId": "c-1",
                            "entityType": "BOOKMARK",
                            "entityId": "bm-1",
                            "operation": "CREATE",
                            "payload": "{}",
                            "changedAt": "%s"
                        }
                    ]
                }
                """.formatted(deviceId, OffsetDateTime.now());

        syncMockMvc.perform(post("/api/v1/sync/push")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accepted[0]").value("c-1"));
    }

    @Test
    void acknowledge_valid_returns200() throws Exception {
        UUID deviceId = UUID.randomUUID();

        String json = """
                {
                    "deviceId": "%s",
                    "cursor": 15
                }
                """.formatted(deviceId);

        syncMockMvc.perform(post("/api/v1/sync/acknowledge")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isOk());

        verify(syncService).acknowledge(eq(testUserId), any(SyncAcknowledgeRequest.class));
    }
}
