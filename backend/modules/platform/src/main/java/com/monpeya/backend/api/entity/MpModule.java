package com.monpeya.backend.api.entity;

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

@Getter
@Setter
@Entity
@Table(name = "MP_MODULE")
public class MpModule {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_module_seq")
	@SequenceGenerator(name = "mp_module_seq", sequenceName = "MP_MODULE_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@Column(name = "CODE", nullable = false, length = 50, unique = true)
	private String code;

	@Column(name = "NAME", nullable = false, length = 120)
	private String name;

	@Column(name = "DESCRIPTION", length = 500)
	private String description;

	/** JSON bag for mobile reuse (iconKey, route, subtitle, accentColor, …). */
	@Column(name = "METADATA_JSON", columnDefinition = "CLOB")
	private String metadataJson;

	/** CLIENT_ONLY (Leadway…) | CLIENT_AND_BUSINESS (tickets client + conductor) */
	@Column(name = "ROLE_MODEL", nullable = false, length = 30)
	private String roleModel = "CLIENT_AND_BUSINESS";

	@Column(name = "IS_ACTIVE", nullable = false)
	private Boolean isActive = true;

	@Column(name = "SORT_ORDER", nullable = false)
	private Integer sortOrder = 0;

	/** GUEST | AUTH | SUBSCRIPTION — required to open the module UI */
	@Column(name = "OPEN_ACCESS_LEVEL", nullable = false, length = 20)
	private String openAccessLevel = "GUEST";

	/** Default for actions not listed in MP_SERVICE_ACTION */
	@Column(name = "DEFAULT_ACTION_LEVEL", nullable = false, length = 20)
	private String defaultActionLevel = "AUTH";

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();

	@Column(name = "UPDATED_AT", nullable = false)
	private LocalDateTime updatedAt = LocalDateTime.now();
}
