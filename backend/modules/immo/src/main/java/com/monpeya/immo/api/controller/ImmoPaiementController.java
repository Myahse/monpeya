package com.monpeya.immo.api.controller;

import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.monpeya.immo.api.service.ImmoPaiementService;

import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/paiements")
@Tag(name = "Immo Paiements")
public class ImmoPaiementController {

    private final ImmoPaiementService paiementService;

    public ImmoPaiementController(ImmoPaiementService paiementService) {
        this.paiementService = paiementService;
    }

    @PostMapping("/getByCriteria")
    public Map<String, Object> listPayments(@RequestBody(required = false) Map<String, Object> body) {
        return paiementService.listByCriteria(body);
    }
}
