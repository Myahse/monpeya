package com.monpeya.immo.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.monpeya.immo.api.entity.ImmoPaiementRecurrent;

public interface ImmoPaiementRecurrentRepository extends JpaRepository<ImmoPaiementRecurrent, String> {

    @Query("""
            SELECT p FROM ImmoPaiementRecurrent p
            LEFT JOIN FETCH p.contrat
            WHERE (:utilisateursId IS NULL OR p.utilisateursId = :utilisateursId)
              AND (:contratsLocationId IS NULL OR p.contrat.contratsLocationId = :contratsLocationId)
            ORDER BY p.prochainPaiement ASC
            """)
    List<ImmoPaiementRecurrent> search(
            @Param("utilisateursId") String utilisateursId,
            @Param("contratsLocationId") String contratsLocationId);
}
