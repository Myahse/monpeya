package com.monpeya.immo.api.service;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.monpeya.immo.api.contracts.ImmoEnvelope;
import com.monpeya.immo.api.entity.ImmoPaiement;
import com.monpeya.immo.api.repository.ImmoPaiementRepository;

@Service
@Transactional("immoTransactionManager")
public class ImmoPaiementService {

    private final ImmoPaiementRepository paiementRepository;

    public ImmoPaiementService(ImmoPaiementRepository paiementRepository) {
        this.paiementRepository = paiementRepository;
    }

    @Transactional(value = "immoTransactionManager", readOnly = true)
    public Map<String, Object> listByCriteria(Map<String, Object> body) {
        Map<String, Object> criteria = ImmoMapper.unwrapData(body);
        String utilisateursId = criteria != null ? stringOrNull(criteria.get("utilisateursId")) : null;
        List<Map<String, Object>> items = ImmoMapper.mapList(
                paiementRepository.search(utilisateursId),
                item -> ImmoMapper.toPaiementMap((ImmoPaiement) item));
        return ImmoEnvelope.ok(items);
    }

    private static String stringOrNull(Object value) {
        if (value == null) {
            return null;
        }
        String text = value.toString().trim();
        return text.isEmpty() ? null : text;
    }
}
