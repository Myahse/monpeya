package com.monpeya.shared.auth;

import java.time.LocalDateTime;
import java.util.Optional;

import org.springframework.stereotype.Component;

import com.monpeya.backend.api.entity.MpSession;
import com.monpeya.backend.api.entity.MpUser;
import com.monpeya.backend.api.repository.MpSessionRepository;

@Component
public class MonPeyaSessionResolver {

    private final MpSessionRepository sessionRepository;

    public MonPeyaSessionResolver(MpSessionRepository sessionRepository) {
        this.sessionRepository = sessionRepository;
    }

    public Optional<MpSession> resolveBearer(String authorizationHeader) {
        String token = extractBearer(authorizationHeader);
        if (token == null) {
            return Optional.empty();
        }
        return resolveAccessToken(token);
    }

    public Optional<MpSession> resolveAccessToken(String accessToken) {
        if (accessToken == null || accessToken.isBlank()) {
            return Optional.empty();
        }
        return sessionRepository.findByAccessTokenAndRevokedFalse(accessToken.trim())
                .filter(session -> session.getExpiresAt().isAfter(LocalDateTime.now()));
    }

    public Optional<MpUser> resolveUser(String accessToken) {
        return resolveAccessToken(accessToken).map(MpSession::getUser);
    }

    public static String extractBearer(String authorizationHeader) {
        if (authorizationHeader == null || authorizationHeader.isBlank()) {
            return null;
        }
        String value = authorizationHeader.trim();
        if (value.regionMatches(true, 0, "Bearer ", 0, 7)) {
            return value.substring(7).trim();
        }
        return value;
    }
}
