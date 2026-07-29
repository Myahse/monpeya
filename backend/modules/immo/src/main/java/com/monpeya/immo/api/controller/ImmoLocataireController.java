package com.monpeya.immo.api.controller;

import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.monpeya.immo.api.service.ImmoLocataireService;

import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/locataires")
@Tag(name = "Immo Locataires")
public class ImmoLocataireController {

    private final ImmoLocataireService locataireService;

    public ImmoLocataireController(ImmoLocataireService locataireService) {
        this.locataireService = locataireService;
    }

    @PostMapping("/getByCriteria")
    public Map<String, Object> listTenants(@RequestBody(required = false) Map<String, Object> body) {
        return locataireService.listByCriteria(body);
    }

    @PostMapping("/create")
    public Map<String, Object> createTenant(@RequestBody Map<String, Object> body) {
        return locataireService.create(body);
    }
}
