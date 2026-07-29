package com.monpeya.server.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;

@Configuration
public class UnifiedOpenApiConfig {

    @Bean
    public OpenAPI monPeyaOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("Mon Peya — Unified Backend")
                        .description("""
                                DDD modules on port 8082:
                                - /api/platform/v1/* — auth, subscriptions, access
                                - /api/billetterie/v1/* — events, tickets, QR
                                - /api/immo/* — (à venir)
                                """)
                        .version("v1"));
    }
}
