package com.monpeya.backend.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpPlanFeature;

public interface MpPlanFeatureRepository extends JpaRepository<MpPlanFeature, Long> {

	List<MpPlanFeature> findByPlan_Id(Long planId);

	boolean existsByPlan_IdAndServiceAction_Id(Long planId, Long serviceActionId);

	boolean existsByPlan_IdAndModule_IdAndServiceActionIsNull(Long planId, Long moduleId);
}
