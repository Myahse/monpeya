package com.djogana.ticketing.api.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.djogana.ticketing.api.contracts.TicketPurpose;
import com.djogana.ticketing.api.contracts.TicketStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "T_TICKET")
@Getter
@Setter
public class TTicket {

	@Id
	@Column(name = "ID", length = 36)
	private String id;

	@Column(name = "TICKET_CODE", length = 30, nullable = false, unique = true)
	private String ticketCode;

	@Column(name = "QR_PAYLOAD", length = 500, nullable = false)
	private String qrPayload;

	@Enumerated(EnumType.STRING)
	@Column(name = "PURPOSE", length = 20, nullable = false)
	private TicketPurpose purpose = TicketPurpose.EVENT;

	@Column(name = "EVENT_ID", length = 36)
	private String eventId;

	@Column(name = "EVENT_CODE", length = 50)
	private String eventCode;

	@Column(name = "ORDER_ID", length = 36)
	private String orderId;

	/** Display title (event name or standalone label e.g. bus route). */
	@Column(name = "EVENT_NAME", length = 300)
	private String eventName;

	@Column(name = "EVENT_PLACE", length = 500)
	private String eventPlace;

	@Column(name = "EVENT_START_AT")
	private LocalDateTime eventStartAt;

	@Column(name = "TICKET_TYPE", length = 50, nullable = false)
	private String ticketType = "STANDARD";

	@Column(name = "PRICE", nullable = false)
	private BigDecimal price;

	@Column(name = "BUILT_BY_CODE_CLIENT", length = 50, nullable = false)
	private String builtByCodeClient;

	@Column(name = "BUILT_BY_NAME", length = 200, nullable = false)
	private String builtByName;

	@Column(name = "GENERATED_AT", nullable = false)
	private LocalDateTime generatedAt;

	@Column(name = "BUYER_CODE_CLIENT", length = 50)
	private String buyerCodeClient;

	@Column(name = "BUYER_NAME", length = 200)
	private String buyerName;

	@Column(name = "BUYER_PHONE", length = 30)
	private String buyerPhone;

	@Column(name = "PURCHASED_AT")
	private LocalDateTime purchasedAt;

	@Column(name = "AMOUNT_PAID")
	private BigDecimal amountPaid;

	@Column(name = "PAYMENT_REFERENCE", length = 100)
	private String paymentReference;

	@Column(name = "REFER_OP", length = 50)
	private String referOp;

	@Column(name = "CONSUMED_AT")
	private LocalDateTime consumedAt;

	@Column(name = "CONSUMED_PLACE", length = 300)
	private String consumedPlace;

	@Column(name = "CONSUMED_BY_CODE_CLIENT", length = 50)
	private String consumedByCodeClient;

	@Column(name = "CONSUMED_BY_NAME", length = 200)
	private String consumedByName;

	@Column(name = "SCANNER_DEVICE_ID", length = 100)
	private String scannerDeviceId;

	@Enumerated(EnumType.STRING)
	@Column(name = "STATUS", length = 20, nullable = false)
	private TicketStatus status;
}
