package com.monpeya.backend.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.monpeya.backend.api.entity.MpAccount;

public interface MpAccountRepository extends JpaRepository<MpAccount, Long> {

	List<MpAccount> findByUser_IdOrderByIsPrincipalDescIdAsc(Long userId);

	Optional<MpAccount> findFirstByUser_IdAndIsPrincipalTrue(Long userId);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("delete from MpAccount a where a.user.id = :userId")
	void deleteByUserId(@Param("userId") Long userId);
}
