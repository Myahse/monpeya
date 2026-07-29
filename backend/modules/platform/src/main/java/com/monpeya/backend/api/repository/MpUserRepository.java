package com.monpeya.backend.api.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpUser;

public interface MpUserRepository extends JpaRepository<MpUser, Long> {

	Optional<MpUser> findByPhone(String phone);

	Optional<MpUser> findByCodeClient(String codeClient);
}
