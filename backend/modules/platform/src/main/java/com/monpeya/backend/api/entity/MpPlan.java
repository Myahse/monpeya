package com.monpeya.backend.api.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * Monpeya subscription / access plan (CLIENT or BUSINESS unlock).
 * Not ticketing fares or product prices — those live in each service app.
 */
@Getter
@Setter
@Entity
@Table(name = "MP_PLAN")
public class MpPlan {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_plan_seq")
	@SequenceGenerator(name = "mp_plan_seq", sequenceName = "MP_PLAN_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@Column(name = "CODE", nullable = false, length = 40, unique = true)
	private String code;

	@Column(name = "NAME", nullable = false, length = 120)
	private String name;

	@Column(name = "DESCRIPTION", length = 500)
	private String description;

	@Column(name = "PRICE", nullable = false, precision = 18, scale = 2)
	private BigDecimal price = BigDecimal.ZERO;

	@Column(name = "CURRENCY", nullable = false, length = 3)
	private String currency = "XOF";

	@Column(name = "BILLING_PERIOD", nullable = false, length = 20)
	private String billingPeriod = "MONTHLY";

	@Column(name = "TRIAL_DAYS", nullable = false)
	private Integer trialDays = 0;

	@Column(name = "IS_DEFAULT", nullable = false)
	private Boolean isDefault = false;

	@Column(name = "IS_ACTIVE", nullable = false)
	private Boolean isActive = true;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();

	@Column(name = "UPDATED_AT", nullable = false)
	private LocalDateTime updatedAt = LocalDateTime.now();
}
