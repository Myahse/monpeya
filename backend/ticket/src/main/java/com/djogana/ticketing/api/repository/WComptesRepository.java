package com.djogana.ticketing.api.repository;

import com.djogana.ticketing.api.contracts.CriteriaUtils;
import com.djogana.ticketing.api.contracts.Request;
import com.djogana.ticketing.api.contracts.Utilities;
import com.djogana.ticketing.api.dto.WComptesDto;
import com.djogana.ticketing.api.entity.WClients;
import com.djogana.ticketing.api.entity.WComptes;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import org.springframework.dao.DataAccessException;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.*;


@Repository
public interface WComptesRepository extends JpaRepository<WComptes, String> {


	@Query(value = "SELECT * FROM W_COMPTES u WHERE u.CODE_CLIENT=:CODE_CLIENT", nativeQuery = true)
	List<WComptes> getCompteOperation(@Param("CODE_CLIENT") String CODE_CLIENT);

	@Query("select e from WComptes e where e.wClients.codeClient = :codeClient")
	WComptes findByCodeClient(@Param("codeClient") String codeClient);

	@Query("select e from WComptes e where e.wClients.codeClient = :codeClient and e.ngc = :ngc")
	WComptes findByCodeClientNcgOne(@Param("codeClient") String codeClient, @Param("ngc") String ngc);

	@Query("select e from WComptes e where e.numerocomptecomplet = :numerocomptecomplet")
	WComptes findByNumeroComptecomplet(@Param("numerocomptecomplet") String numerocomptecomplet);

	@Query("select e from WComptes e where e.wClients.codeClient = :codeClient")
	List <WComptes> findByCodeClientList(@Param("codeClient") String codeClient);


	@Query("select e from WComptes e where e.dateouverture = :dateouverture")
	List<WComptes> findByDateouverture(@Param("dateouverture") Date dateouverture);

	@Query("select e from WComptes e where e.datefermture = :datefermture")
	List<WComptes> findByDatefermture(@Param("datefermture") Date datefermture);


	@Query("select e from WComptes e where e.codedevise = :codedevise")
	List<WComptes> findByCodedevise(@Param("codedevise") String codedevise);

	@Query("select e from WComptes e where e.soldedispo = :soldedispo")
	List<WComptes> findBySoldedispo(@Param("soldedispo") BigDecimal soldedispo);


	@Query("select e from WComptes e where e.soldecompta = :soldecompta")
	List<WComptes> findBySoldecompta(@Param("soldecompta") BigDecimal soldecompta);


	@Query("select e from WComptes e where e.soldeautorisation = :soldeautorisation")
	List<WComptes> findBySoldeautorisation(@Param("soldeautorisation") BigDecimal soldeautorisation);


	@Query("select e from WComptes e where e.datederniermvt = :datederniermvt")
	List<WComptes> findByDatederniermvt(@Param("datederniermvt") Date datederniermvt);


	@Query("select e from WComptes e where e.codeBanque = :codeBanque")
	List<WComptes> findByCodeBanque(@Param("codeBanque") String codeBanque);


	@Query("select e from WComptes e where e.codeAgence = :codeAgence")
	List<WComptes> findByCodeAgence(@Param("codeAgence") String codeAgence);


	@Query("select e from WComptes e where e.codeSur = :codeSur")
	List<WComptes> findByCodeSur(@Param("codeSur") String codeSur);

	@Query("select e from WComptes e where e.ngc = :ngc")
	WComptes findByNgc(@Param("ngc") String ngc);


	@Query("select e from WComptes e where e.bloquage = :bloquage")
	List<WComptes> findByBloquage(@Param("bloquage") BigDecimal bloquage);

	@Query("select e from WComptes e where e.codePack = :codePack")
	List<WComptes> findByCodePack(@Param("codePack") String codePack);


	@Query("select e from WComptes e where e.ncpteParrain = :ncpteParrain")
	List<WComptes> findByNcpteParrain(@Param("ncpteParrain") String ncpteParrain);

	public default List<WComptes> getByCriteria(Request<WComptesDto> request, EntityManager em, Locale locale)
			throws DataAccessException, Exception {
		String req = "select e from WComptes e where e IS NOT NULL";
		HashMap<String, Object> param = new HashMap<String, Object>();
		req += getWhereExpression(request, param, locale);
		req += " order by idwComptes desc";
		TypedQuery<WComptes> query = em.createQuery(req, WComptes.class);
		for (Map.Entry<String, Object> entry : param.entrySet()) {
			query.setParameter(entry.getKey(), entry.getValue());
		}
		if (request.getIndex() != null && request.getSize() != null) {
			query.setFirstResult(request.getIndex() * request.getSize());
			query.setMaxResults(request.getSize());
		}
		return query.getResultList();
	}

	public default Long count(Request<WComptesDto> request, EntityManager em, Locale locale)
			throws DataAccessException, Exception {
		String req = "select count(e.id) from WComptes e where e IS NOT NULL";
		HashMap<String, Object> param = new HashMap<String, Object>();
		req += getWhereExpression(request, param, locale);
		req += " order by idwComptes  desc";
		jakarta.persistence.Query query = em.createQuery(req);
		for (Map.Entry<String, Object> entry : param.entrySet()) {
			query.setParameter(entry.getKey(), entry.getValue());
		}
		Long count = (Long) query.getResultList().get(0);
		return count;
	}

	default String getWhereExpression(Request<WComptesDto> request, HashMap<String, Object> param, Locale locale)
			throws Exception {
		// main query
		WComptesDto dto = request.getData() != null ? request.getData() : new WComptesDto();
		String mainReq = generateCriteria(dto, param, 0, locale);
		// others query
		String othersReq = "";
		if (request.getDatas() != null && !request.getDatas().isEmpty()) {
			Integer index = 1;
			for (WComptesDto elt : request.getDatas()) {
				String eltReq = generateCriteria(elt, param, index, locale);
				if (request.getIsAnd() != null && request.getIsAnd()) {
					othersReq += "and (" + eltReq + ") ";
				} else {
					othersReq += "or (" + eltReq + ") ";
				}
				index++;
			}
		}
		String req = "";
		if (!mainReq.isEmpty()) {
			req += " and (" + mainReq + ") ";
		}
		req += othersReq;
		return req;
	}

	default String generateCriteria(WComptesDto dto, HashMap<String, Object> param, Integer index, Locale locale)
			throws Exception {
		List<String> listOfQuery = new ArrayList<String>();
		if (dto != null) {
			if (dto.getIdwComptes() != null && dto.getIdwComptes().intValue() > 0) {
				listOfQuery.add(CriteriaUtils.generateCriteria("idwComptes", dto.getIdwComptes(), "e.idwComptes",
						"BigDecimal", dto.getIdwComptesParam(), param, index));
			}
			if (Utilities.notBlank(dto.getCodeClient())) {
				listOfQuery.add(CriteriaUtils.generateCriteria("codeClient", dto.getCodeClient(), "e.codeClient",
						"String", dto.getCodeClientParam(), param, index));
			}



			if (Utilities.notBlank(dto.getCodedevise())) {
				listOfQuery.add(CriteriaUtils.generateCriteria("codedevise", dto.getCodedevise(), "e.codedevise",
						"String", dto.getCodedeviseParam(), param, index));
			}
			if (dto.getSoldedispo() != null && dto.getSoldedispo().intValue() > 0) {
				listOfQuery.add(CriteriaUtils.generateCriteria("soldedispo", dto.getSoldedispo(), "e.soldedispo",
						"BigDecimal", dto.getSoldedispoParam(), param, index));
			}

			if (dto.getSoldecompta() != null && dto.getSoldecompta().intValue() > 0) {
				listOfQuery.add(CriteriaUtils.generateCriteria("soldecompta", dto.getSoldecompta(), "e.soldecompta",
						"BigDecimal", dto.getSoldecomptaParam(), param, index));
			}
			if (dto.getSoldeautorisation() != null && dto.getSoldeautorisation().intValue() > 0) {
				listOfQuery.add(CriteriaUtils.generateCriteria("soldeautorisation", dto.getSoldeautorisation(),
						"e.soldeautorisation", "BigDecimal", dto.getSoldeautorisationParam(), param, index));
			}

			if (Utilities.notBlank(dto.getCodeBanque())) {
				listOfQuery.add(CriteriaUtils.generateCriteria("codeBanque", dto.getCodeBanque(), "e.codeBanque",
						"String", dto.getCodeBanqueParam(), param, index));
			}
			if (Utilities.notBlank(dto.getCodeAgence())) {
				listOfQuery.add(CriteriaUtils.generateCriteria("codeAgence", dto.getCodeAgence(), "e.codeAgence",
						"String", dto.getCodeAgenceParam(), param, index));
			}


			if (Utilities.notBlank(dto.getCodeSur())) {
				listOfQuery.add(CriteriaUtils.generateCriteria("codeSur", dto.getCodeSur(), "e.codeSur", "String",
						dto.getCodeSurParam(), param, index));
			}
			if (Utilities.notBlank(dto.getNumerocomptecomplet())) {
				listOfQuery.add(CriteriaUtils.generateCriteria("numerocomptecomplet", dto.getNumerocomptecomplet(),
						"e.numerocomptecomplet", "String", dto.getNumerocomptecompletParam(), param, index));
			}

			if (Utilities.notBlank(dto.getNgc())) {
				listOfQuery.add(CriteriaUtils.generateCriteria("ngc", dto.getNgc(), "e.ngc", "String",
						dto.getNgcParam(), param, index));
			}


			if (dto.getBloquage() != null && dto.getBloquage().intValue() > 0) {
				listOfQuery.add(CriteriaUtils.generateCriteria("bloquage", dto.getBloquage(), "e.bloquage",
						"BigDecimal", dto.getBloquageParam(), param, index));
			}
			if (Utilities.notBlank(dto.getCodePack())) {
				listOfQuery.add(CriteriaUtils.generateCriteria("codePack", dto.getCodePack(), "e.codePack", "String",
						dto.getCodePackParam(), param, index));
			}
			if (Utilities.notBlank(dto.getNcpteParrain())) {
				listOfQuery.add(CriteriaUtils.generateCriteria("ncpteParrain", dto.getNcpteParrain(), "e.ncpteParrain",
						"String", dto.getNcpteParrainParam(), param, index));
			}

		}
		return CriteriaUtils.getCriteriaByListOfQuery(listOfQuery);
	}
}
