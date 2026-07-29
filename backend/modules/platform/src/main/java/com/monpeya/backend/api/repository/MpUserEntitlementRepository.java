package com.monpeya.backend.api.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.monpeya.backend.api.entity.MpUserEntitlement;

public interface MpUserEntitlementRepository extends JpaRepository<MpUserEntitlement, Long> {

	@Query("""
			select e from MpUserEntitlement e
			where e.user.id = :userId
			  and e.isActive = true
			  and (e.expiresAt is null or e.expiresAt > :now)
			""")
	List<MpUserEntitlement> findValidByUserId(@Param("userId") Long userId, @Param("now") LocalDateTime now);
}
