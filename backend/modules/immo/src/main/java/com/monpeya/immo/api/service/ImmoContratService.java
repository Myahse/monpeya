package com.monpeya.immo.api.service;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.monpeya.immo.api.contracts.ImmoEnvelope;
import com.monpeya.immo.api.entity.ImmoBien;
import com.monpeya.immo.api.entity.ImmoContratLocation;
import com.monpeya.immo.api.entity.ImmoLocataire;
import com.monpeya.immo.api.entity.ImmoPaiementRecurrent;
import com.monpeya.immo.api.repository.ImmoBienRepository;
import com.monpeya.immo.api.repository.ImmoContratLocationRepository;
import com.monpeya.immo.api.repository.ImmoLocataireRepository;
import com.monpeya.immo.api.repository.ImmoPaiementRecurrentRepository;

@Service
@Transactional("immoTransactionManager")
public class ImmoContratService {

    private final ImmoContratLocationRepository contratRepository;
    private final ImmoPaiementRecurrentRepository recurrentRepository;
    private final ImmoBienRepository bienRepository;
    private final ImmoLocataireRepository locataireRepository;

    public ImmoContratService(
            ImmoContratLocationRepository contratRepository,
            ImmoPaiementRecurrentRepository recurrentRepository,
            ImmoBienRepository bienRepository,
            ImmoLocataireRepository locataireRepository) {
        this.contratRepository = contratRepository;
        this.recurrentRepository = recurrentRepository;
        this.bienRepository = bienRepository;
        this.locataireRepository = locataireRepository;
    }

    @Transactional(value = "immoTransactionManager", readOnly = true)
    public Map<String, Object> listContrats(Map<String, Object> body) {
        Map<String, Object> criteria = ImmoMapper.unwrapData(body);
        List<Map<String, Object>> items = ImmoMapper.mapList(
                contratRepository.search(
                        stringOrNull(criteria.get("utilisateursId")),
                        stringOrNull(criteria.get("contratsLocationId")),
                        stringOrNull(criteria.get("biensId")),
                        stringOrNull(criteria.get("locatairesId"))),
                item -> ImmoMapper.toContratMap((ImmoContratLocation) item));
        return ImmoEnvelope.ok(items);
    }

    public Map<String, Object> createContrat(Map<String, Object> body) {
        Map<String, Object> data = ImmoMapper.unwrapData(body);
        ImmoBien bien = bienRepository.findById(requiredId(data, "biensId")).orElseThrow();
        ImmoLocataire locataire = locataireRepository.findById(requiredId(data, "locatairesId")).orElseThrow();
        ImmoContratLocation saved = contratRepository.save(ImmoMapper.fromContratPayload(data, bien, locataire));
        return ImmoEnvelope.item(ImmoMapper.toContratMap(saved));
    }

    @Transactional(value = "immoTransactionManager", readOnly = true)
    public Map<String, Object> listPaiementsRecurrents(Map<String, Object> body) {
        Map<String, Object> criteria = ImmoMapper.unwrapData(body);
        List<Map<String, Object>> items = ImmoMapper.mapList(
                recurrentRepository.search(
                        stringOrNull(criteria.get("utilisateursId")),
                        stringOrNull(criteria.get("contratsLocationId"))),
                item -> ImmoMapper.toPaiementRecurrentMap((ImmoPaiementRecurrent) item));
        return ImmoEnvelope.ok(items);
    }

    public Map<String, Object> createPaiementRecurrent(Map<String, Object> body) {
        Map<String, Object> data = ImmoMapper.unwrapData(body);
        ImmoContratLocation contrat = contratRepository
                .findById(requiredId(data, "contratsLocationId"))
                .orElseThrow();
        ImmoPaiementRecurrent saved = recurrentRepository
                .save(ImmoMapper.fromPaiementRecurrentPayload(data, contrat));
        return ImmoEnvelope.item(ImmoMapper.toPaiementRecurrentMap(saved));
    }

    private static String requiredId(Map<String, Object> data, String key) {
        String value = stringOrNull(data.get(key));
        if (value == null) {
            throw new IllegalArgumentException(key + " requis");
        }
        return value;
    }

    private static String stringOrNull(Object value) {
        if (value == null) {
            return null;
        }
        String text = value.toString().trim();
        return text.isEmpty() ? null : text;
    }
}
