package com.monpeya.immo.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.monpeya.immo.api.entity.ImmoPaiement;

public interface ImmoPaiementRepository extends JpaRepository<ImmoPaiement, String> {

    @Query("""
            SELECT p FROM ImmoPaiement p
            WHERE (:utilisateursId IS NULL OR p.utilisateursId = :utilisateursId)
            ORDER BY p.datePaiement DESC
            """)
    List<ImmoPaiement> search(@Param("utilisateursId") String utilisateursId);
}
