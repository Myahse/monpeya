package com.monpeya.backend.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpOtpChallenge;

public interface MpOtpChallengeRepository extends JpaRepository<MpOtpChallenge, Long> {
}
