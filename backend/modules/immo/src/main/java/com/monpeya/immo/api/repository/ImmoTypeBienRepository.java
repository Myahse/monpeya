package com.monpeya.immo.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.monpeya.immo.api.entity.ImmoTypeBien;

public interface ImmoTypeBienRepository extends JpaRepository<ImmoTypeBien, String> {
}
