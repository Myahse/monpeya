package com.monpeya.immo.api.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.monpeya.immo.api.entity.ImmoBien;
import com.monpeya.immo.api.entity.ImmoCodePays;
import com.monpeya.immo.api.entity.ImmoContratLocation;
import com.monpeya.immo.api.entity.ImmoLocataire;
import com.monpeya.immo.api.entity.ImmoMessage;
import com.monpeya.immo.api.entity.ImmoPaiement;
import com.monpeya.immo.api.entity.ImmoPaiementRecurrent;
import com.monpeya.immo.api.entity.ImmoTypeBien;

public final class ImmoMapper {

    private static final ObjectMapper JSON = new ObjectMapper();

    private ImmoMapper() {
    }

    static Map<String, Object> toBienMap(ImmoBien bien) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("biensId", bien.getBiensId());
        map.put("id", bien.getBiensId());
        map.put("nom", bien.getNom());
        map.put("description", bien.getDescription());
        map.put("prix", bien.getPrix());
        map.put("superficie", bien.getSuperficie());
        map.put("adresse", bien.getAdresse());
        map.put("ville", bien.getVille());
        map.put("codePostal", bien.getCodePostal());
        map.put("latitude", bien.getLatitude());
        map.put("longitude", bien.getLongitude());
        map.put("photo", bien.getPhoto());
        map.put("statut", bien.getStatut());
        map.put("statuts", Map.of("libelle", labelStatut(bien.getStatut()), "code", bien.getStatut()));
        map.put("dateCreation", bien.getDateCreation());
        map.put("createdAt", bien.getDateCreation());
        map.put("evaluationQualite", bien.getEvaluationQualite());
        map.put("caracteristiques", parseCommodities(bien.getCommodities()));
        map.put("images", parseImages(bien.getPhoto()));

        if (bien.getTypeBiens() != null) {
            map.put("typeBiens", toTypeMap(bien.getTypeBiens()));
        }
        if (bien.getCodePays() != null) {
            map.put("codePays", toPaysMap(bien.getCodePays()));
        }
        return map;
    }

    static Map<String, Object> toLocataireMap(ImmoLocataire locataire) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("locatairesId", locataire.getLocatairesId());
        map.put("id", locataire.getLocatairesId());
        map.put("nom", locataire.getNom());
        map.put("prenoms", locataire.getPrenoms());
        map.put("email", locataire.getEmail());
        map.put("telephone", locataire.getTelephone());
        map.put("statut", locataire.getStatut());
        map.put("photo", locataire.getPhoto());
        map.put("profession", locataire.getProfession());
        map.put("revenuMensuel", locataire.getRevenuMensuel());
        if (locataire.getBien() != null) {
            map.put("propertyName", locataire.getBien().getNom());
            map.put("propertyAddress", locataire.getBien().getAdresse());
        }
        return map;
    }

    static Map<String, Object> toPaiementMap(ImmoPaiement paiement) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("paiementsId", paiement.getPaiementsId());
        map.put("id", paiement.getPaiementsId());
        map.put("montant", paiement.getMontant());
        map.put("datePaiement", paiement.getDatePaiement());
        map.put("commentaire", paiement.getCommentaire());
        map.put("contratsLocationId", paiement.getContratsLocationId());
        if (paiement.getLocataire() != null) {
            map.put("locatairesId", paiement.getLocataire().getLocatairesId());
        }
        return map;
    }

    public static Map<String, Object> toPaysMap(ImmoCodePays pays) {
        return Map.of("id", pays.getId(), "nom", pays.getNom(), "code", pays.getCode());
    }

    static Map<String, Object> toTypeMap(ImmoTypeBien type) {
        return Map.of("id", type.getId(), "libelle", type.getLibelle(), "nom", type.getNom());
    }

    static Map<String, Object> toMessageMap(ImmoMessage message) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("messagesId", message.getMessagesId());
        map.put("id", message.getMessagesId());
        map.put("senderId", message.getSenderId());
        map.put("receiverId", message.getReceiverId());
        map.put("content", message.getContent());
        map.put("sentAt", message.getSentAt());
        map.put("isRead", Boolean.TRUE.equals(message.getIsRead()));
        return map;
    }

    static ImmoBien fromCreatePayload(Map<String, Object> data, ImmoTypeBien type, ImmoCodePays pays) {
        ImmoBien bien = new ImmoBien();
        bien.setBiensId(UUID.randomUUID().toString());
        bien.setNom(stringValue(data.get("nom"), "Sans titre"));
        bien.setDescription(stringValue(data.get("description"), null));
        bien.setPrix(decimalValue(data.get("prix")));
        bien.setSuperficie(decimalValue(data.get("superficie")));
        bien.setAdresse(stringValue(data.get("adresse"), null));
        bien.setVille(stringValue(data.get("ville"), null));
        bien.setCodePostal(stringValue(data.get("codePostal"), null));
        bien.setLatitude(decimalValue(data.get("latitude")));
        bien.setLongitude(decimalValue(data.get("longitude")));
        bien.setPhoto(stringValue(data.get("photo"), null));
        bien.setCommodities(stringValue(data.get("commodities"), null));
        bien.setStatut(stringValue(data.get("statut"), "libre"));
        bien.setUtilisateursId(stringValue(data.get("utilisateursId"), null));
        bien.setDateCreation(LocalDateTime.now());
        bien.setDateAcquisition(parseDate(stringValue(data.get("dateAcquisition"), null)));
        bien.setTypeBiens(type);
        bien.setCodePays(pays);
        return bien;
    }

    static ImmoLocataire fromCreatePayload(Map<String, Object> data, ImmoBien bien) {
        ImmoLocataire locataire = new ImmoLocataire();
        locataire.setLocatairesId(UUID.randomUUID().toString());
        locataire.setNom(stringValue(data.get("nom"), ""));
        locataire.setPrenoms(stringValue(data.get("prenoms"), null));
        locataire.setEmail(stringValue(data.get("email"), null));
        locataire.setTelephone(stringValue(data.get("telephone"), null));
        locataire.setCni(stringValue(data.get("cni"), null));
        locataire.setAdresse(stringValue(data.get("adresse"), null));
        locataire.setProfession(stringValue(data.get("profession"), null));
        locataire.setRevenuMensuel(decimalValue(data.get("revenuMensuel")));
        locataire.setDateNaissance(parseDateTime(stringValue(data.get("dateNaissance"), null)));
        locataire.setStatut(stringValue(data.get("statut"), "actif"));
        locataire.setPhoto(stringValue(data.get("photo"), null));
        locataire.setUtilisateursId(stringValue(data.get("utilisateursId"), null));
        locataire.setMontantLoyer(decimalValue(data.get("montantLoyer")));
        locataire.setFrequencePaiement(stringValue(data.get("frequencePaiement"), null));
        locataire.setDateDebutBail(parseDateTime(stringValue(data.get("dateDebutBail"), null)));
        locataire.setDateFinBail(parseDateTime(stringValue(data.get("dateFinBail"), null)));
        locataire.setJourPaiement(intValue(data.get("jourPaiement")));
        locataire.setBien(bien);
        return locataire;
    }

    public static Map<String, Object> toContratMap(ImmoContratLocation contrat) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("contratsLocationId", contrat.getContratsLocationId());
        map.put("id", contrat.getContratsLocationId());
        map.put("montantLoyer", contrat.getMontantLoyer());
        map.put("frequencePaiement", contrat.getFrequencePaiement());
        map.put("jourPaiement", contrat.getJourPaiement());
        map.put("dateDebut", contrat.getDateDebut());
        map.put("dateFin", contrat.getDateFin());
        map.put("statut", contrat.getStatut());
        map.put("utilisateursId", contrat.getUtilisateursId());
        if (contrat.getBien() != null) {
            map.put("biensId", contrat.getBien().getBiensId());
            map.put("propertyName", contrat.getBien().getNom());
        }
        if (contrat.getLocataire() != null) {
            map.put("locatairesId", contrat.getLocataire().getLocatairesId());
            map.put("tenantName", contrat.getLocataire().getPrenoms() + " " + contrat.getLocataire().getNom());
        }
        return map;
    }

    public static Map<String, Object> toPaiementRecurrentMap(ImmoPaiementRecurrent recurrent) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("paiementsRecurrentsId", recurrent.getPaiementsRecurrentsId());
        map.put("id", recurrent.getPaiementsRecurrentsId());
        map.put("montant", recurrent.getMontant());
        map.put("frequence", recurrent.getFrequence());
        map.put("prochainPaiement", recurrent.getProchainPaiement());
        map.put("dernierPaiement", recurrent.getDernierPaiement());
        map.put("statut", recurrent.getStatut());
        map.put("utilisateursId", recurrent.getUtilisateursId());
        if (recurrent.getContrat() != null) {
            map.put("contratsLocationId", recurrent.getContrat().getContratsLocationId());
        }
        return map;
    }

    public static ImmoContratLocation fromContratPayload(
            Map<String, Object> data,
            ImmoBien bien,
            ImmoLocataire locataire) {
        ImmoContratLocation contrat = new ImmoContratLocation();
        contrat.setContratsLocationId(UUID.randomUUID().toString());
        contrat.setBien(bien);
        contrat.setLocataire(locataire);
        contrat.setUtilisateursId(stringValue(data.get("utilisateursId"), null));
        contrat.setMontantLoyer(decimalValue(data.get("montantLoyer")));
        contrat.setFrequencePaiement(stringValue(data.get("frequencePaiement"), "monthly"));
        contrat.setJourPaiement(intValue(data.get("jourPaiement")));
        contrat.setDateDebut(parseDateTime(stringValue(data.get("dateDebut"), null)));
        contrat.setDateFin(parseDateTime(stringValue(data.get("dateFin"), null)));
        contrat.setStatut(stringValue(data.get("statut"), "actif"));
        contrat.setDateCreation(LocalDateTime.now());
        return contrat;
    }

    public static ImmoPaiementRecurrent fromPaiementRecurrentPayload(
            Map<String, Object> data,
            ImmoContratLocation contrat) {
        ImmoPaiementRecurrent recurrent = new ImmoPaiementRecurrent();
        recurrent.setPaiementsRecurrentsId(UUID.randomUUID().toString());
        recurrent.setContrat(contrat);
        recurrent.setUtilisateursId(stringValue(data.get("utilisateursId"), null));
        recurrent.setMontant(decimalValue(data.get("montant")));
        recurrent.setFrequence(stringValue(data.get("frequence"), "monthly"));
        recurrent.setProchainPaiement(parseDateTime(stringValue(data.get("prochainPaiement"), null)));
        recurrent.setDernierPaiement(parseDateTime(stringValue(data.get("dernierPaiement"), null)));
        recurrent.setStatut(stringValue(data.get("statut"), "actif"));
        recurrent.setDateCreation(LocalDateTime.now());
        return recurrent;
    }

    @SuppressWarnings("unchecked")
    static Map<String, Object> unwrapData(Map<String, Object> body) {
        if (body == null) {
            return Map.of();
        }
        Object data = body.get("data");
        if (data instanceof Map<?, ?> nested) {
            return (Map<String, Object>) nested;
        }
        return body;
    }

    private static String labelStatut(String statut) {
        if (statut == null) {
            return "—";
        }
        return switch (statut.toLowerCase()) {
            case "libre" -> "Libre";
            case "occupe" -> "Occupé";
            case "attente" -> "En attente";
            default -> statut;
        };
    }

    private static List<String> parseCommodities(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        try {
            return JSON.readValue(raw, new TypeReference<List<String>>() {
            });
        } catch (Exception ignored) {
            return List.of(raw);
        }
    }

    private static List<String> parseImages(String photo) {
        if (photo == null || photo.isBlank()) {
            return List.of();
        }
        if (photo.startsWith("[")) {
            try {
                return JSON.readValue(photo, new TypeReference<List<String>>() {
                });
            } catch (Exception ignored) {
                return List.of(photo);
            }
        }
        return List.of(photo);
    }

    private static String stringValue(Object value, String defaultValue) {
        if (value == null) {
            return defaultValue;
        }
        String text = value.toString().trim();
        return text.isEmpty() ? defaultValue : text;
    }

    private static BigDecimal decimalValue(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof BigDecimal decimal) {
            return decimal;
        }
        if (value instanceof Number number) {
            return BigDecimal.valueOf(number.doubleValue());
        }
        try {
            return new BigDecimal(value.toString());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private static Integer intValue(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number number) {
            return number.intValue();
        }
        try {
            return Integer.parseInt(value.toString());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private static LocalDate parseDate(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(value.substring(0, Math.min(10, value.length())));
        } catch (DateTimeParseException ex) {
            return null;
        }
    }

    private static LocalDateTime parseDateTime(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException ex) {
            return parseDate(value) != null ? parseDate(value).atStartOfDay() : null;
        }
    }

    public static List<Map<String, Object>> mapList(List<?> source, java.util.function.Function<Object, Map<String, Object>> mapper) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (Object item : source) {
            items.add(mapper.apply(item));
        }
        return items;
    }
}
