package com.monpeya.immo.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.monpeya.immo.api.entity.ImmoLocataire;

public interface ImmoLocataireRepository extends JpaRepository<ImmoLocataire, String> {

    @Query("""
            SELECT l FROM ImmoLocataire l
            LEFT JOIN FETCH l.bien
            WHERE (:utilisateursId IS NULL OR l.utilisateursId = :utilisateursId)
              AND (:locatairesId IS NULL OR l.locatairesId = :locatairesId)
            ORDER BY l.nom ASC
            """)
    List<ImmoLocataire> search(
            @Param("utilisateursId") String utilisateursId,
            @Param("locatairesId") String locatairesId);
}
