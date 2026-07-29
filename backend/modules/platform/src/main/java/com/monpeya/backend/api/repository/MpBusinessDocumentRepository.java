package com.monpeya.backend.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.backend.api.entity.MpBusinessDocument;

public interface MpBusinessDocumentRepository extends JpaRepository<MpBusinessDocument, Long> {

	List<MpBusinessDocument> findByProfile_IdOrderByCreatedAtDesc(Long profileId);
}
