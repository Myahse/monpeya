package com.monpeya.backend.api.entity;

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

@Getter
@Setter
@Entity
@Table(name = "MP_SUBSCRIPTION")
public class MpSubscription {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_subscription_seq")
	@SequenceGenerator(name = "mp_subscription_seq", sequenceName = "MP_SUBSCRIPTION_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "USER_ID", nullable = false)
	private MpUser user;

	/** Optional — plan types not defined yet. */
	@ManyToOne(fetch = FetchType.EAGER)
	@JoinColumn(name = "PLAN_ID")
	private MpPlan plan;

	/** Service this subscription unlocks (null = legacy global mock). */
	@ManyToOne(fetch = FetchType.EAGER)
	@JoinColumn(name = "MODULE_ID")
	private MpModule module;

	/** CLIENT | BUSINESS */
	@Column(name = "ROLE", nullable = false, length = 20)
	private String role = "CLIENT";

	/** TRIAL | ACTIVE | PAST_DUE | CANCELLED | EXPIRED */
	@Column(name = "STATUS", nullable = false, length = 20)
	private String status;

	@Column(name = "START_AT", nullable = false)
	private LocalDateTime startAt;

	@Column(name = "END_AT")
	private LocalDateTime endAt;

	@Column(name = "TRIAL_END_AT")
	private LocalDateTime trialEndAt;

	@Column(name = "AUTO_RENEW", nullable = false)
	private Boolean autoRenew = false;

	@Column(name = "CANCELLED_AT")
	private LocalDateTime cancelledAt;

	/** Always PEYAPAY for Monpeya; real charge not enabled yet. */
	@Column(name = "PAYMENT_PROVIDER", nullable = false, length = 30)
	private String paymentProvider = "PEYAPAY";

	/** PENDING | MOCK_PAID | PAID | FAILED */
	@Column(name = "PAYMENT_STATUS", nullable = false, length = 30)
	private String paymentStatus = "MOCK_PAID";

	@Column(name = "PAYMENT_REF", length = 100)
	private String paymentRef;

	@Column(name = "IS_MOCK_PAYMENT", nullable = false)
	private Boolean isMockPayment = true;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();

	@Column(name = "UPDATED_AT", nullable = false)
	private LocalDateTime updatedAt = LocalDateTime.now();
}
