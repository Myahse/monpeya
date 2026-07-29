package com.monpeya.immo.api.controller;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.monpeya.backend.api.contracts.Request;
import com.monpeya.backend.api.contracts.Response;
import com.monpeya.backend.api.dto.AuthPhoneDto;
import com.monpeya.backend.api.dto.AuthSessionDto;
import com.monpeya.backend.api.dto.AuthUserDto;
import com.monpeya.backend.api.service.AuthBusiness;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Immo Auth", description = "Mr Immo login bridged to Mon Peya platform session")
public class ImmoAuthController {

    private final AuthBusiness authBusiness;

    public ImmoAuthController(AuthBusiness authBusiness) {
        this.authBusiness = authBusiness;
    }

    @PostMapping("/login")
    @Operation(summary = "Login with phone + PIN — returns Mon Peya access token as immo JWT")
    public ResponseEntity<Map<String, Object>> login(
            @RequestBody Map<String, String> body,
            Locale locale) {
        String login = body != null ? trim(body.get("login")) : null;
        String password = body != null ? trim(body.get("password")) : null;

        if (login == null || password == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error("login et password requis"));
        }

        Request<AuthPhoneDto> request = new Request<>();
        AuthPhoneDto data = new AuthPhoneDto();
        data.setPhone(login);
        data.setPin(password);
        request.setData(data);

        Response<AuthSessionDto> platformResponse = authBusiness.login(request, locale);
        if (platformResponse.isHasError() || platformResponse.getItem() == null) {
            String message = platformResponse.getStatus() != null
                    ? platformResponse.getStatus().getMessage()
                    : "Connexion impossible";
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error(message));
        }

        AuthSessionDto session = platformResponse.getItem();
        AuthUserDto user = session.getUser();
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("token", session.getAccessToken());
        payload.put("suspended", false);
        if (user != null && user.getUserId() != null) {
            payload.put("utilisateursId", user.getUserId());
            payload.put("id", user.getUserId());
        }
        return ResponseEntity.ok(payload);
    }

    private static Map<String, Object> error(String message) {
        return Map.of("success", false, "message", message);
    }

    private static String trim(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
