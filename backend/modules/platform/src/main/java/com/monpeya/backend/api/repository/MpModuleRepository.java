package com.monpeya.backend.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpModule;

public interface MpModuleRepository extends JpaRepository<MpModule, Long> {

	Optional<MpModule> findByCodeAndIsActiveTrue(String code);

	List<MpModule> findByIsActiveTrueOrderBySortOrderAsc();
}
