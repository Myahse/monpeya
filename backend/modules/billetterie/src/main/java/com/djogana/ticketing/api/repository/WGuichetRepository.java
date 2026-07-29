package com.djogana.ticketing.api.repository;

import com.djogana.ticketing.api.entity.WGuichet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface WGuichetRepository extends JpaRepository<WGuichet, String> {

    @Query("select e from WGuichet e where e.numguichet = :numguichet")
    WGuichet findByCodeWGuichet(@Param("numguichet") String numguichet);

    @Query("""
            select e
            from WGuichet e
            where e.codeOperation = :codeOperation
              and e.codeoperationbq = :codeoperationbq
              and e.compteDebit = :compteDebit
              and e.compteCredit = :compteCredit
              and e.montant = :montant
            order by e.dateoperation desc, e.heureoperation desc
            """)
    java.util.List<WGuichet> findLatestForOperation(@Param("codeOperation") String codeOperation,
                                                    @Param("codeoperationbq") String codeoperationbq,
                                                    @Param("compteDebit") String compteDebit,
                                                    @Param("compteCredit") String compteCredit,
                                                    @Param("montant") BigDecimal montant);

    @Query("""
            select distinct e.login
            from WGuichet e
            where e.codeBanque = :codeBanque
              and e.codeAgence = :codeAgence
              and e.login is not null
              and trim(e.login) <> ''
            order by e.login asc
            """)
    List<String> findDistinctLogins(@Param("codeBanque") String codeBanque,
                                    @Param("codeAgence") String codeAgence);

    @Query("""
            select e.login
            from WGuichet e
            where e.login is not null
              and trim(e.login) <> ''
            order by e.dateoperation desc, e.heureoperation desc
            """)
    List<String> findRecentLogins(Pageable pageable);
}

