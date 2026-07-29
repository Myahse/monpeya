package com.monpeya.backend.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpModuleParam;

public interface MpModuleParamRepository extends JpaRepository<MpModuleParam, Long> {

	List<MpModuleParam> findByModule_IdAndIsActiveTrueOrderBySortOrderAscParamKeyAsc(Long moduleId);
}
