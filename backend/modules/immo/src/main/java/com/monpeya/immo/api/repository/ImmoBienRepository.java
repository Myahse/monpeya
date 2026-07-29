package com.monpeya.immo.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.monpeya.immo.api.entity.ImmoBien;

public interface ImmoBienRepository extends JpaRepository<ImmoBien, String> {

    @Query("""
            SELECT b FROM ImmoBien b
            WHERE (:nom IS NULL OR LOWER(b.nom) LIKE LOWER(CONCAT(CONCAT('%', :nom), '%')))
              AND (:utilisateursId IS NULL OR b.utilisateursId = :utilisateursId)
            ORDER BY b.dateCreation DESC
            """)
    List<ImmoBien> search(@Param("nom") String nom, @Param("utilisateursId") String utilisateursId);
}
