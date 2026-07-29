package com.djogana.ticketing.api.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "Create event payload (inside Request.data)")
public class EventCreateDto implements CodeClientHolder {

	@Schema(description = "Creator Peya codeClient", example = "ABC123", requiredMode = Schema.RequiredMode.REQUIRED)
	private String codeClient;
	@Schema(example = "Summer Fest", requiredMode = Schema.RequiredMode.REQUIRED)
	private String name;
	@Schema(example = "CONCERT", requiredMode = Schema.RequiredMode.REQUIRED)
	private String category;
	private String venueName;
	private String address;
	private String city;
	private String country;
	private BigDecimal latitude;
	private BigDecimal longitude;
	private LocalDateTime startAt;
	private LocalDateTime endAt;
	private BigDecimal ticketPrice;
	private Integer maxTickets;
}
