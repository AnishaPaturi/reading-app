package com.readingsanctuary.api.sync.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.readingsanctuary.api.sync.entity.SyncDevice;

@Repository
public interface SyncDeviceRepository extends JpaRepository<SyncDevice, UUID> {

    List<SyncDevice> findByUser_IdAndIsActiveTrue(UUID userId);

    List<SyncDevice> findByUser_Id(UUID userId);

    Optional<SyncDevice> findByIdAndUser_Id(UUID id, UUID userId);
}
