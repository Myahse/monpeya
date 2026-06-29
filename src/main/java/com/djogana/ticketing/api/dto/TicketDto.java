package com.djogana.ticketing.api.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.djogana.ticketing.api.contracts.TicketPurpose;
import com.djogana.ticketing.api.contracts.TicketStatus;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "Ticket response — identified by ticketCode")
public class TicketDto {

	@Schema(description = "Public ticket code", example = "TKT-A1B2C3D4")
	private String ticketCode;

	private String qrPayload;

	@Schema(description = "EVENT, TRANSPORT, PASS, or GENERIC")
	private TicketPurpose purpose;

	@Schema(description = "Set for EVENT tickets only", example = "EVT-2026-A1B2C3D4")
	private String eventCode;

	@Schema(example = "ORD-A1B2C3D4")
	private String orderRef;

	@Schema(description = "Event name or standalone label (e.g. bus route)")
	private String title;

	private String place;
	private LocalDateTime validFrom;
	private String ticketType;
	private BigDecimal price;
	private String builtByCodeClient;
	private String builtByName;
	private LocalDateTime generatedAt;
	private String buyerCodeClient;
	private String buyerName;
	private String buyerPhone;
	private LocalDateTime purchasedAt;
	private BigDecimal amountPaid;
	private String paymentReference;
	private String referOp;
	private LocalDateTime consumedAt;
	private String consumedPlace;
	private String consumedByCodeClient;
	private String consumedByName;
	private String scannerDeviceId;
	private TicketStatus status;
}
