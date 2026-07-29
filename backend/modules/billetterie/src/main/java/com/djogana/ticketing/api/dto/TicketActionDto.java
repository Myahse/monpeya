package com.djogana.ticketing.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "Lookup a ticket by public ticket code")
public class TicketActionDto {

	@Schema(description = "Public ticket code", example = "TKT-A1B2C3D4", requiredMode = Schema.RequiredMode.REQUIRED)
	private String ticketCode;
}
