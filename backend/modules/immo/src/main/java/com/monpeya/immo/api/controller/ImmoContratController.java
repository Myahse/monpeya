package com.monpeya.immo.api.controller;

import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.monpeya.immo.api.service.ImmoContratService;

import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api")
@Tag(name = "Immo Contrats")
public class ImmoContratController {

    private final ImmoContratService contratService;

    public ImmoContratController(ImmoContratService contratService) {
        this.contratService = contratService;
    }

    @PostMapping("/contratsLocation/getByCriteria")
    public Map<String, Object> listContrats(@RequestBody(required = false) Map<String, Object> body) {
        return contratService.listContrats(body);
    }

    @PostMapping("/contratsLocation/create")
    public Map<String, Object> createContrat(@RequestBody Map<String, Object> body) {
        return contratService.createContrat(body);
    }

    @PostMapping("/paiementsRecurrents/getByCriteria")
    public Map<String, Object> listPaiementsRecurrents(@RequestBody(required = false) Map<String, Object> body) {
        return contratService.listPaiementsRecurrents(body);
    }

    @PostMapping("/paiementsRecurrents/create")
    public Map<String, Object> createPaiementRecurrent(@RequestBody Map<String, Object> body) {
        return contratService.createPaiementRecurrent(body);
    }
}
