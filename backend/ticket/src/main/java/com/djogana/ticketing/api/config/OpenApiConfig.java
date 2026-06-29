package com.djogana.ticketing.api.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;

@Configuration
public class OpenApiConfig {

	@Bean
	public OpenAPI ticketingOpenApi() {
		return new OpenAPI()
				.info(new Info()
						.title("Ticketing API")
						.description("""
								Multi-purpose ticketing backend (Peya integration).

								**Conventions**
								- All endpoints: **POST** with `{ "data": { ... } }`
								- User identity: Peya `codeClient`
								- Public identifiers: `eventCode` (events), `ticketCode` (tickets) — not UUIDs

								**Ticket purposes:** `EVENT` (linked to an event), `TRANSPORT` (conductor/bus), `PASS`, `GENERIC`

								**Event flow:** create → generate (`eventCode`) → publish → buy (`ticketCode`) → verify/consume QR

								**Standalone flow:** generate without `eventCode` (set `purpose`, `title`, `validFrom`, `price`) → buy → consume
								""")
						.version("v1")
						.contact(new Contact().name("Djogana").email("support@djogana.com"))
						.license(new License().name("Proprietary")))
				.addServersItem(new Server().url("http://localhost:8090").description("Local dev"));
	}
}
