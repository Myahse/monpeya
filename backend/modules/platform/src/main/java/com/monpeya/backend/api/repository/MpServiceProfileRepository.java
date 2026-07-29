package com.monpeya.backend.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpServiceProfile;

public interface MpServiceProfileRepository extends JpaRepository<MpServiceProfile, Long> {

	List<MpServiceProfile> findByUser_IdOrderByModule_SortOrderAsc(Long userId);

	Optional<MpServiceProfile> findByUser_IdAndModule_Code(Long userId, String moduleCode);
}
