package com.djogana.ticketing.api.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.djogana.ticketing.api.contracts.PaymentStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "T_ORDER")
@Getter
@Setter
public class TOrder {

	@Id
	@Column(name = "ID", length = 36)
	private String id;

	@Column(name = "ORDER_REF", length = 50, nullable = false, unique = true)
	private String orderRef;

	@Column(name = "EVENT_ID", length = 36)
	private String eventId;

	@Column(name = "TICKET_ID", length = 36, nullable = false)
	private String ticketId;

	@Column(name = "BUYER_CODE_CLIENT", length = 50, nullable = false)
	private String buyerCodeClient;

	@Column(name = "BUYER_NAME", length = 200, nullable = false)
	private String buyerName;

	@Column(name = "BUYER_PHONE", length = 30, nullable = false)
	private String buyerPhone;

	@Column(name = "CODE_CLIENT", length = 50)
	private String codeClient;

	@Column(name = "AMOUNT", nullable = false)
	private BigDecimal amount;

	@Enumerated(EnumType.STRING)
	@Column(name = "PAYMENT_STATUS", length = 20, nullable = false)
	private PaymentStatus paymentStatus;

	@Column(name = "PAYMENT_METHOD", length = 30)
	private String paymentMethod;

	@Column(name = "PAYMENT_REFERENCE", length = 100)
	private String paymentReference;

	@Column(name = "REFER_OP", length = 50)
	private String referOp;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt;

	@Column(name = "PAID_AT")
	private LocalDateTime paidAt;
}
