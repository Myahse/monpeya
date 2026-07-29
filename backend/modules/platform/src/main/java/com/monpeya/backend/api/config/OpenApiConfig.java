package com.monpeya.backend.api.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;

@Configuration
public class OpenApiConfig {

	@Bean
	public OpenAPI monpeyaOpenApi() {
		return new OpenAPI()
				.info(new Info()
						.title("Monpeya Backend API")
						.description("Super-app auth and orchestration. Identity is verified via PeyaPay; sessions live in Oracle.")
						.version("v1"));
	}
}
