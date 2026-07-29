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
@Table(name = "MP_SERVICE_ACTION")
public class MpServiceAction {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_service_action_seq")
	@SequenceGenerator(name = "mp_service_action_seq", sequenceName = "MP_SERVICE_ACTION_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "MODULE_ID", nullable = false)
	private MpModule module;

	@Column(name = "CODE", nullable = false, length = 80)
	private String code;

	@Column(name = "NAME", nullable = false, length = 120)
	private String name;

	@Column(name = "DESCRIPTION", length = 500)
	private String description;

	/** GUEST | AUTH | SUBSCRIPTION */
	@Column(name = "ACCESS_LEVEL", nullable = false, length = 20)
	private String accessLevel = "AUTH";

	/** ANY | CLIENT | BUSINESS */
	@Column(name = "REQUIRED_ROLE", nullable = false, length = 20)
	private String requiredRole = "ANY";

	@Column(name = "IS_ACTIVE", nullable = false)
	private Boolean isActive = true;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();
}
