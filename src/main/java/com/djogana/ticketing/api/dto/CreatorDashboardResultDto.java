package com.djogana.ticketing.api.dto;

import java.util.List;

import lombok.Data;

@Data
public class CreatorDashboardResultDto {

	private List<EventDto> events;
	private long totalTicketsGenerated;
	private long totalTicketsSold;
	private long totalTicketsConsumed;
}
