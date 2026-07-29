package com.monpeya.backend.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpDevice;

public interface MpDeviceRepository extends JpaRepository<MpDevice, Long> {

	Optional<MpDevice> findFirstByUser_IdAndImei(Long userId, String imei);

	List<MpDevice> findByUser_Id(Long userId);
}
