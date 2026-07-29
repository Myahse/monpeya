package com.monpeya.immo.api.controller;

import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.monpeya.immo.api.repository.ImmoCodePaysRepository;
import com.monpeya.immo.api.service.ImmoMapper;
import com.monpeya.immo.api.service.ImmoMessageService;

import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@Tag(name = "Immo Misc")
public class ImmoMiscController {

    private final ImmoCodePaysRepository codePaysRepository;
    private final ImmoMessageService messageService;

    public ImmoMiscController(ImmoCodePaysRepository codePaysRepository, ImmoMessageService messageService) {
        this.codePaysRepository = codePaysRepository;
        this.messageService = messageService;
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP", "module", "immo");
    }

    @PostMapping("/api/codePays/getByCriteria")
    public Map<String, Object> listCountries(@RequestBody(required = false) Map<String, Object> body) {
        List<Map<String, Object>> items = ImmoMapper.mapList(
                codePaysRepository.findAll(),
                item -> ImmoMapper.toPaysMap((com.monpeya.immo.api.entity.ImmoCodePays) item));
        return com.monpeya.immo.api.contracts.ImmoEnvelope.ok(items);
    }

    @GetMapping("/api/messages/conversations/{userId}")
    public List<Map<String, Object>> conversations(@PathVariable String userId) {
        return messageService.listConversations(userId);
    }

    @GetMapping("/api/messages/conversation")
    public List<Map<String, Object>> conversation(
            @RequestParam String user1Id,
            @RequestParam String user2Id) {
        return messageService.listConversation(user1Id, user2Id);
    }

    @PostMapping("/api/messages")
    public Map<String, Object> sendMessage(@RequestBody Map<String, Object> body) {
        return messageService.send(body);
    }
}
