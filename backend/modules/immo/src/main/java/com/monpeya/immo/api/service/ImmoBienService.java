package com.monpeya.immo.api.service;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.monpeya.immo.api.contracts.ImmoEnvelope;
import com.monpeya.immo.api.entity.ImmoBien;
import com.monpeya.immo.api.entity.ImmoCodePays;
import com.monpeya.immo.api.entity.ImmoTypeBien;
import com.monpeya.immo.api.repository.ImmoBienRepository;
import com.monpeya.immo.api.repository.ImmoCodePaysRepository;
import com.monpeya.immo.api.repository.ImmoTypeBienRepository;

@Service
@Transactional("immoTransactionManager")
public class ImmoBienService {

    private final ImmoBienRepository bienRepository;
    private final ImmoTypeBienRepository typeBienRepository;
    private final ImmoCodePaysRepository codePaysRepository;

    public ImmoBienService(
            ImmoBienRepository bienRepository,
            ImmoTypeBienRepository typeBienRepository,
            ImmoCodePaysRepository codePaysRepository) {
        this.bienRepository = bienRepository;
        this.typeBienRepository = typeBienRepository;
        this.codePaysRepository = codePaysRepository;
    }

    @Transactional(value = "immoTransactionManager", readOnly = true)
    public Map<String, Object> listByCriteria(Map<String, Object> body) {
        Map<String, Object> criteria = ImmoMapper.unwrapData(body);
        String nom = stringOrNull(criteria.get("nom"));
        String utilisateursId = stringOrNull(criteria.get("utilisateursId"));
        List<Map<String, Object>> items = ImmoMapper.mapList(
                bienRepository.search(nom, utilisateursId),
                item -> ImmoMapper.toBienMap((ImmoBien) item));
        return ImmoEnvelope.ok(items);
    }

    @Transactional(value = "immoTransactionManager", readOnly = true)
    public Map<String, Object> getPublic(String id) {
        Optional<ImmoBien> bien = bienRepository.findById(id);
        return bien.map(value -> ImmoEnvelope.item(ImmoMapper.toBienMap(value)))
                .orElseGet(() -> ImmoEnvelope.ok(List.of()));
    }

    public Map<String, Object> create(Map<String, Object> body) {
        Map<String, Object> data = ImmoMapper.unwrapData(body);
        ImmoTypeBien type = resolveType(stringOrNull(data.get("typeBiensId")));
        ImmoCodePays pays = resolvePays(stringOrNull(data.get("codePaysId")));
        ImmoBien saved = bienRepository.save(ImmoMapper.fromCreatePayload(data, type, pays));
        return ImmoEnvelope.item(ImmoMapper.toBienMap(saved));
    }

    private ImmoTypeBien resolveType(String typeBiensId) {
        if (typeBiensId == null) {
            return typeBienRepository.findAll().stream().findFirst().orElse(null);
        }
        return typeBienRepository.findById(typeBiensId).orElse(null);
    }

    private ImmoCodePays resolvePays(String codePaysId) {
        if (codePaysId == null) {
            return codePaysRepository.findAll().stream().findFirst().orElse(null);
        }
        return codePaysRepository.findById(codePaysId).orElse(null);
    }

    private static String stringOrNull(Object value) {
        if (value == null) {
            return null;
        }
        String text = value.toString().trim();
        return text.isEmpty() ? null : text;
    }
}
