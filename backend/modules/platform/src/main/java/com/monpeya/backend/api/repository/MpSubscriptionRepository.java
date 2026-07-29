package com.monpeya.backend.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.monpeya.backend.api.entity.MpSubscription;

public interface MpSubscriptionRepository extends JpaRepository<MpSubscription, Long> {

	@Query("""
			select s from MpSubscription s
			where s.user.id = :userId
			  and s.status in ('TRIAL', 'ACTIVE')
			order by s.startAt desc
			""")
	List<MpSubscription> findActiveByUserId(@Param("userId") Long userId);

	@Query("""
			select s from MpSubscription s
			where s.user.id = :userId
			  and s.status in ('TRIAL', 'ACTIVE')
			  and s.module.code = :moduleCode
			  and s.role = :role
			order by s.startAt desc
			""")
	List<MpSubscription> findActiveByUserModuleRole(
			@Param("userId") Long userId,
			@Param("moduleCode") String moduleCode,
			@Param("role") String role);

	@Query("""
			select s from MpSubscription s
			where s.user.id = :userId
			  and s.status in ('TRIAL', 'ACTIVE')
			  and s.module.code = :moduleCode
			order by s.startAt desc
			""")
	List<MpSubscription> findActiveByUserModule(
			@Param("userId") Long userId,
			@Param("moduleCode") String moduleCode);

	default Optional<MpSubscription> findCurrentByUserId(Long userId) {
		List<MpSubscription> list = findActiveByUserId(userId);
		return list.isEmpty() ? Optional.empty() : Optional.of(list.get(0));
	}

	default Optional<MpSubscription> findCurrentByUserModuleRole(Long userId, String moduleCode, String role) {
		List<MpSubscription> list = findActiveByUserModuleRole(userId, moduleCode, role);
		return list.isEmpty() ? Optional.empty() : Optional.of(list.get(0));
	}

	List<MpSubscription> findByUser_IdOrderByStartAtDesc(Long userId);
}
