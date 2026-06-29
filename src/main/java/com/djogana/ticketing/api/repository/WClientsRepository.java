package com.djogana.ticketing.api.repository;

import com.djogana.ticketing.api.entity.WClients;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface WClientsRepository extends JpaRepository<WClients, String> {

   
    @Query("select e from WClients e where e.codeClient = :codeClient")
    WClients findOneByCodeClient(@Param("codeClient") String codeClient);

    @Query("select e from WClients e where e.gsmPrincipale = :gsm")
    WClients findOneByGsmPrincipale(@Param("gsm") String gsm);

    @Query("select e from WClients e where e.accountId = :accountId")
    WClients findOneByAccountId(@Param("accountId") String accountId);

    default WClients findByCodeClientOrNull(String codeClient) {
        if (codeClient == null || codeClient.isBlank()) {
            return null;
        }
        return findOneByCodeClient(codeClient.trim());
    }

    default WClients findByGsmPrincipaleOrNull(String gsm) {
        if (gsm == null || gsm.isBlank()) {
            return null;
        }
        return findOneByGsmPrincipale(gsm.trim());
    }

    default WClients findByAccountIdOrNull(String accountId) {
        if (accountId == null || accountId.isBlank()) {
            return null;
        }
        return findOneByAccountId(accountId.trim());
    }
}
