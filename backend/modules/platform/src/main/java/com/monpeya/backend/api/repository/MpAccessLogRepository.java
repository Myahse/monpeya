package com.monpeya.backend.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpAccessLog;

public interface MpAccessLogRepository extends JpaRepository<MpAccessLog, Long> {
}
