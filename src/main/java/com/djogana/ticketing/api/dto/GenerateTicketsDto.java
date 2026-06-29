package com.djogana.ticketing.api.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.djogana.ticketing.api.contracts.TicketPurpose;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "Generate tickets — event-linked (eventCode) or standalone (purpose + title)")
public class GenerateTicketsDto implements CodeClientHolder {

	@Schema(description = "Event code when purpose is EVENT", example = "EVT-2026-A1B2C3D4")
	private String eventCode;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private String codeClient;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private Integer quantity;

	@Schema(example = "STANDARD")
	private String ticketType;

	@Schema(description = "EVENT (default when eventCode set), TRANSPORT, PASS, GENERIC")
	private TicketPurpose purpose;

	@Schema(description = "Standalone ticket title (required when eventCode is absent)")
	private String title;

	private String place;

	private LocalDateTime validFrom;

	private LocalDateTime validUntil;

	@Schema(description = "Standalone price (required when eventCode is absent)")
	private BigDecimal price;
}
