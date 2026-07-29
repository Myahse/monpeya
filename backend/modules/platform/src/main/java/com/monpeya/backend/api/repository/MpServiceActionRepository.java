package com.monpeya.backend.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpServiceAction;

public interface MpServiceActionRepository extends JpaRepository<MpServiceAction, Long> {

	Optional<MpServiceAction> findByModule_CodeAndCodeAndIsActiveTrue(String moduleCode, String actionCode);

	List<MpServiceAction> findByModule_CodeAndIsActiveTrue(String moduleCode);
}
