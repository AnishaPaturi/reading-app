package com.readingsanctuary.api.sync.service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.sync.dto.DeviceRegistrationRequest;
import com.readingsanctuary.api.sync.dto.DeviceResponse;
import com.readingsanctuary.api.sync.entity.SyncDevice;
import com.readingsanctuary.api.sync.repository.SyncDeviceRepository;
import com.readingsanctuary.api.user.entity.User;
import com.readingsanctuary.api.user.repository.UserRepository;

@Service
@Transactional
public class DeviceService {

    private final SyncDeviceRepository deviceRepository;
    private final UserRepository userRepository;

    public DeviceService(SyncDeviceRepository deviceRepository, UserRepository userRepository) {
        this.deviceRepository = deviceRepository;
        this.userRepository = userRepository;
    }

    public DeviceResponse registerDevice(UUID userId, DeviceRegistrationRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        SyncDevice device = new SyncDevice();
        device.setUser(user);
        device.setDeviceName(request.deviceName());
        device.setPlatform(request.platform().toUpperCase());
        device.setActive(true);
        device.setLastSeenAt(OffsetDateTime.now());

        SyncDevice saved = deviceRepository.save(device);
        return toDeviceResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<DeviceResponse> listDevices(UUID userId) {
        return deviceRepository.findByUser_Id(userId).stream()
                .map(this::toDeviceResponse)
                .toList();
    }

    public void deactivateDevice(UUID userId, UUID deviceId) {
        SyncDevice device = deviceRepository.findByIdAndUser_Id(deviceId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Device not found"));

        device.setActive(false);
        deviceRepository.save(device);
    }

    public SyncDevice validateActiveDevice(UUID userId, UUID deviceId) {
        SyncDevice device = deviceRepository.findByIdAndUser_Id(deviceId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Device not found or not owned by user"));

        if (!device.isActive()) {
            throw new IllegalStateException("Device has been deactivated");
        }

        device.setLastSeenAt(OffsetDateTime.now());
        return deviceRepository.save(device);
    }

    public void updateCursor(UUID userId, UUID deviceId, long cursor) {
        SyncDevice device = validateActiveDevice(userId, deviceId);
        device.setLastSyncCursor(cursor);
        device.setLastSeenAt(OffsetDateTime.now());
        deviceRepository.save(device);
    }

    private DeviceResponse toDeviceResponse(SyncDevice device) {
        return new DeviceResponse(
                device.getId(),
                device.getDeviceName(),
                device.getPlatform(),
                device.getLastSyncCursor(),
                device.getLastSeenAt(),
                device.isActive(),
                device.getCreatedAt()
        );
    }
}
