package com.monpeya.immo.api.controller;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.monpeya.immo.api.service.ImmoBienService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/biens")
@Tag(name = "Immo Biens")
public class ImmoBienController {

    private final ImmoBienService bienService;

    public ImmoBienController(ImmoBienService bienService) {
        this.bienService = bienService;
    }

    @PostMapping("/getByCriteria")
    @Operation(summary = "List properties")
    public Map<String, Object> listProperties(@RequestBody(required = false) Map<String, Object> body) {
        return bienService.listByCriteria(body);
    }

    @GetMapping("/public/{id}")
    @Operation(summary = "Public property detail")
    public Map<String, Object> publicProperty(@PathVariable String id) {
        return bienService.getPublic(id);
    }

    @PostMapping("/create")
    @Operation(summary = "Create property")
    public Map<String, Object> createProperty(@RequestBody Map<String, Object> body) {
        return bienService.create(body);
    }
}
