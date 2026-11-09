package com.readingsanctuary.api.sync.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record DeviceRegistrationRequest(
        @NotBlank(message = "deviceName is required")
        @Size(max = 150, message = "deviceName must not exceed 150 characters")
        String deviceName,

        @NotBlank(message = "platform is required")
        @Size(max = 30, message = "platform must not exceed 30 characters")
        String platform
) {
}
