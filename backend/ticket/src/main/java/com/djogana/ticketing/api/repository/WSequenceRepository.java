package com.djogana.ticketing.api.repository;

import com.djogana.ticketing.api.entity.WSequence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface WSequenceRepository extends JpaRepository<WSequence, String> {

    @Query("select e from WSequence e where e.nomFichier = :nomFichier")
    WSequence findByNomFichier(@Param("nomFichier") String nomFichier);

}



