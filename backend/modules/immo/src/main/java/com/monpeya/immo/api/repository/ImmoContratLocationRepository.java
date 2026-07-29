package com.monpeya.immo.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.monpeya.immo.api.entity.ImmoContratLocation;

public interface ImmoContratLocationRepository extends JpaRepository<ImmoContratLocation, String> {

    @Query("""
            SELECT c FROM ImmoContratLocation c
            LEFT JOIN FETCH c.bien
            LEFT JOIN FETCH c.locataire
            WHERE (:utilisateursId IS NULL OR c.utilisateursId = :utilisateursId)
              AND (:contratsLocationId IS NULL OR c.contratsLocationId = :contratsLocationId)
              AND (:biensId IS NULL OR c.bien.biensId = :biensId)
              AND (:locatairesId IS NULL OR c.locataire.locatairesId = :locatairesId)
            ORDER BY c.dateCreation DESC
            """)
    List<ImmoContratLocation> search(
            @Param("utilisateursId") String utilisateursId,
            @Param("contratsLocationId") String contratsLocationId,
            @Param("biensId") String biensId,
            @Param("locatairesId") String locatairesId);
}
