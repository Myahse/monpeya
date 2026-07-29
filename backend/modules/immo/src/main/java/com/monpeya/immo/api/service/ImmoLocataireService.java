package com.monpeya.immo.api.service;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.monpeya.immo.api.contracts.ImmoEnvelope;
import com.monpeya.immo.api.entity.ImmoBien;
import com.monpeya.immo.api.entity.ImmoLocataire;
import com.monpeya.immo.api.repository.ImmoBienRepository;
import com.monpeya.immo.api.repository.ImmoLocataireRepository;

@Service
@Transactional("immoTransactionManager")
public class ImmoLocataireService {

    private final ImmoLocataireRepository locataireRepository;
    private final ImmoBienRepository bienRepository;

    public ImmoLocataireService(ImmoLocataireRepository locataireRepository, ImmoBienRepository bienRepository) {
        this.locataireRepository = locataireRepository;
        this.bienRepository = bienRepository;
    }

    @Transactional(value = "immoTransactionManager", readOnly = true)
    public Map<String, Object> listByCriteria(Map<String, Object> body) {
        Map<String, Object> criteria = ImmoMapper.unwrapData(body);
        String utilisateursId = stringOrNull(criteria.get("utilisateursId"));
        String locatairesId = stringOrNull(criteria.get("locatairesId"));
        List<Map<String, Object>> items = ImmoMapper.mapList(
                locataireRepository.search(utilisateursId, locatairesId),
                item -> ImmoMapper.toLocataireMap((ImmoLocataire) item));
        return ImmoEnvelope.ok(items);
    }

    public Map<String, Object> create(Map<String, Object> body) {
        Map<String, Object> data = ImmoMapper.unwrapData(body);
        ImmoBien bien = null;
        String biensId = stringOrNull(data.get("biensId"));
        if (biensId != null) {
            bien = bienRepository.findById(biensId).orElse(null);
        }
        ImmoLocataire saved = locataireRepository.save(ImmoMapper.fromCreatePayload(data, bien));
        return ImmoEnvelope.item(ImmoMapper.toLocataireMap(saved));
    }

    private static String stringOrNull(Object value) {
        if (value == null) {
            return null;
        }
        String text = value.toString().trim();
        return text.isEmpty() ? null : text;
    }
}
