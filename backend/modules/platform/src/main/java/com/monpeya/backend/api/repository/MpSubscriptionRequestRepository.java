package com.monpeya.backend.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.monpeya.backend.api.entity.MpSubscriptionRequest;

public interface MpSubscriptionRequestRepository extends JpaRepository<MpSubscriptionRequest, Long> {

	List<MpSubscriptionRequest> findByUser_IdOrderByCreatedAtDesc(Long userId);

	@Query("""
			select r from MpSubscriptionRequest r
			where r.user.id = :userId
			  and r.requestType = :type
			  and r.status in ('WAITING_FOR_APPROVAL', 'ON_REVIEW')
			order by r.createdAt desc
			""")
	List<MpSubscriptionRequest> findOpenByUserAndType(
			@Param("userId") Long userId,
			@Param("type") String type);

	Optional<MpSubscriptionRequest> findByIdAndUser_Id(Long id, Long userId);
}
