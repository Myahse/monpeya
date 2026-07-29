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
@Table(name = "MP_MODULE_PARAM")
public class MpModuleParam {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_module_param_seq")
	@SequenceGenerator(name = "mp_module_param_seq", sequenceName = "MP_MODULE_PARAM_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "MODULE_ID", nullable = false)
	private MpModule module;

	@Column(name = "PARAM_KEY", nullable = false, length = 80)
	private String paramKey;

	@Column(name = "PARAM_VALUE", length = 1000)
	private String paramValue;

	@Column(name = "SORT_ORDER", nullable = false)
	private Integer sortOrder = 0;

	@Column(name = "IS_ACTIVE", nullable = false)
	private Boolean isActive = true;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();
}
