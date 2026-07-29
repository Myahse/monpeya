package com.monpeya.backend.api.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpSession;

public interface MpSessionRepository extends JpaRepository<MpSession, Long> {

	Optional<MpSession> findByAccessTokenAndRevokedFalse(String accessToken);

	Optional<MpSession> findByRefreshTokenAndRevokedFalse(String refreshToken);
}
