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
@Table(name = "MP_SERVICE_PROFILE")
public class MpServiceProfile {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_service_profile_seq")
	@SequenceGenerator(name = "mp_service_profile_seq", sequenceName = "MP_SERVICE_PROFILE_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "USER_ID", nullable = false)
	private MpUser user;

	@ManyToOne(fetch = FetchType.EAGER, optional = false)
	@JoinColumn(name = "MODULE_ID", nullable = false)
	private MpModule module;

	/** CLIENT | BUSINESS */
	@Column(name = "CURRENT_ROLE", nullable = false, length = 20)
	private String currentRole = "CLIENT";

	/** NONE | PENDING_DOCS | PENDING_REVIEW | APPROVED | REJECTED */
	@Column(name = "BUSINESS_STATUS", nullable = false, length = 30)
	private String businessStatus = "NONE";

	/** DOCUMENTS | PEYAPAY_MERCHANT */
	@Column(name = "UPGRADE_PATH", length = 30)
	private String upgradePath;

	@Column(name = "IS_PEYAPAY_MERCHANT", nullable = false)
	private Boolean isPeyapayMerchant = false;

	@Column(name = "NOTE", length = 500)
	private String note;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();

	@Column(name = "UPDATED_AT", nullable = false)
	private LocalDateTime updatedAt = LocalDateTime.now();
}
