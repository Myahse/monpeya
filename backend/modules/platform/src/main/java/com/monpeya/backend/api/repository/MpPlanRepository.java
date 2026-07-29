package com.monpeya.backend.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpPlan;

public interface MpPlanRepository extends JpaRepository<MpPlan, Long> {

	Optional<MpPlan> findByCodeAndIsActiveTrue(String code);

	Optional<MpPlan> findFirstByIsDefaultTrueAndIsActiveTrue();

	List<MpPlan> findByIsActiveTrueOrderByPriceAsc();
}
