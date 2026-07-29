package com.djogana.ticketing.api.repository;

import com.djogana.ticketing.api.entity.WReferenceOperation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;


public interface WReferenceOperationRepository extends JpaRepository<WReferenceOperation, BigDecimal> {
	@Query("select e from WReferenceOperation e where e.codeOperation = :codeOperation")
	List<WReferenceOperation> findByCodeOperation(@Param("codeOperation")String codeOperation);

	@Query("select e from WReferenceOperation e where e.codeOperation = :codeOperation and e.codeBanque = :codeBanque ")
	List<WReferenceOperation> findByCodeOperation(@Param("codeOperation")String codeOperation,@Param("codeBanque")String codeBanque);
	
	@Query("select e from WReferenceOperation e order by idReferenceOperation desc ")
	List<WReferenceOperation> findLast();

}
