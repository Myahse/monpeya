package com.monpeya.backend.api.entity;

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
@Table(name = "MP_PLAN_FEATURE")
public class MpPlanFeature {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_plan_feature_seq")
	@SequenceGenerator(name = "mp_plan_feature_seq", sequenceName = "MP_PLAN_FEATURE_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "PLAN_ID", nullable = false)
	private MpPlan plan;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "MODULE_ID")
	private MpModule module;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "SERVICE_ACTION_ID")
	private MpServiceAction serviceAction;

	@Column(name = "FEATURE_CODE", nullable = false, length = 80)
	private String featureCode;

	@Column(name = "DESCRIPTION", length = 300)
	private String description;
}
