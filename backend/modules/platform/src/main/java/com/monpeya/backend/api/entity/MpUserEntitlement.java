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
@Table(name = "MP_USER_ENTITLEMENT")
public class MpUserEntitlement {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_user_entitlement_seq")
	@SequenceGenerator(name = "mp_user_entitlement_seq", sequenceName = "MP_USER_ENTITLEMENT_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "USER_ID", nullable = false)
	private MpUser user;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "MODULE_ID")
	private MpModule module;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "SERVICE_ACTION_ID")
	private MpServiceAction serviceAction;

	@Column(name = "FEATURE_CODE", nullable = false, length = 80)
	private String featureCode;

	@Column(name = "SOURCE", nullable = false, length = 40)
	private String source = "MANUAL";

	@Column(name = "GRANTED_AT", nullable = false)
	private LocalDateTime grantedAt = LocalDateTime.now();

	@Column(name = "EXPIRES_AT")
	private LocalDateTime expiresAt;

	@Column(name = "IS_ACTIVE", nullable = false)
	private Boolean isActive = true;

	@Column(name = "NOTE", length = 300)
	private String note;
}
