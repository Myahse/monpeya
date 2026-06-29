package com.djogana.ticketing.api.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.djogana.ticketing.api.contracts.EventStatus;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "Event response — identified by eventCode")
public class EventDto {

	@Schema(description = "Public event code", example = "EVT-2026-A1B2C3D4")
	private String eventCode;

	@Schema(description = "Creator Peya codeClient")
	private String codeClient;

	private String creatorName;
	private String creatorPhone;
	private String name;
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
	private Integer ticketsGenerated;
	private Integer ticketsSold;
	private Integer ticketsConsumed;
	private EventStatus status;
	private LocalDateTime createdAt;
	private LocalDateTime publishedAt;
}
