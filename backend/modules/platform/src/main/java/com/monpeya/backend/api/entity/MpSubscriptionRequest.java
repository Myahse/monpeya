package com.monpeya.backend.api.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * BUSINESS subscribe: debit at launch → approval workflow.
 * DEPLAFONNEMENT: client must be approved before straight CLIENT debit subscribe.
 */
@Getter
@Setter
@Entity
@Table(name = "MP_SUBSCRIPTION_REQUEST")
public class MpSubscriptionRequest {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_sub_request_seq")
	@SequenceGenerator(name = "mp_sub_request_seq", sequenceName = "MP_SUB_REQUEST_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "USER_ID", nullable = false)
	private MpUser user;

	@ManyToOne(fetch = FetchType.EAGER)
	@JoinColumn(name = "MODULE_ID")
	private MpModule module;

	@ManyToOne(fetch = FetchType.EAGER)
	@JoinColumn(name = "PLAN_ID")
	private MpPlan plan;

	/** CLIENT | BUSINESS */
	@Column(name = "ROLE", nullable = false, length = 20)
	private String role = "CLIENT";

	/** BUSINESS_SUBSCRIBE | DEPLAFONNEMENT */
	@Column(name = "REQUEST_TYPE", nullable = false, length = 30)
	private String requestType;

	@Column(name = "AMOUNT", nullable = false, precision = 18, scale = 2)
	private BigDecimal amount = BigDecimal.ZERO;

	@Column(name = "CURRENCY", nullable = false, length = 3)
	private String currency = "XOF";

	/** WAITING_FOR_APPROVAL | ON_REVIEW | APPROVED | REJECTED */
	@Column(name = "STATUS", nullable = false, length = 30)
	private String status = "WAITING_FOR_APPROVAL";

	@Column(name = "PAYMENT_PROVIDER", nullable = false, length = 30)
	private String paymentProvider = "PEYAPAY";

	@Column(name = "PAYMENT_STATUS", nullable = false, length = 30)
	private String paymentStatus = "MOCK_PAID";

	@Column(name = "PAYMENT_REF", length = 100)
	private String paymentRef;

	@Column(name = "IS_MOCK_PAYMENT", nullable = false)
	private Boolean isMockPayment = true;

	@Column(name = "DEBITED_AT")
	private LocalDateTime debitedAt;

	@Column(name = "REVIEWED_AT")
	private LocalDateTime reviewedAt;

	@Column(name = "REVIEW_NOTE", length = 500)
	private String reviewNote;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "SUBSCRIPTION_ID")
	private MpSubscription subscription;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();

	@Column(name = "UPDATED_AT", nullable = false)
	private LocalDateTime updatedAt = LocalDateTime.now();
}
