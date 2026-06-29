package com.djogana.ticketing.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "Purchase a ticket by public ticket code")
public class BuyTicketDto implements CodeClientHolder {

	@Schema(description = "Public ticket code", example = "TKT-A1B2C3D4", requiredMode = Schema.RequiredMode.REQUIRED)
	private String ticketCode;

	@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
	private String codeClient;

	@Schema(example = "PEYA_WALLET")
	private String paymentMethod;
}
