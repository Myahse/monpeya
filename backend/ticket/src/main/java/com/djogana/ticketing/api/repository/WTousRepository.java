package com.djogana.ticketing.api.repository;

import com.djogana.ticketing.api.entity.WTous;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;

@Repository
public interface WTousRepository extends JpaRepository<WTous, BigDecimal> {

    @Query("select e from WTous e where e.codeTous = :codeTous")
    WTous findByCodeTous(@Param("codeTous") String codeTous);
}

