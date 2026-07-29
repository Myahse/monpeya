package com.monpeya.backend.api.dto;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class PlanDto {
	private String code;
	private String name;
	private String description;
	private BigDecimal price;
	private String currency;
	private String billingPeriod;
	private Integer trialDays;
	private Boolean isDefault;
	/** CLIENT | BUSINESS — from .env priced catalog. */
	private String role;
	/** SINGLE = one module | GROUPED = several modules. */
	private String planKind;
	private List<String> moduleCodes = new ArrayList<>();

	public String getCode() {
		return code;
	}

	public void setCode(String code) {
		this.code = code;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public BigDecimal getPrice() {
		return price;
	}

	public void setPrice(BigDecimal price) {
		this.price = price;
	}

	public String getCurrency() {
		return currency;
	}

	public void setCurrency(String currency) {
		this.currency = currency;
	}

	public String getBillingPeriod() {
		return billingPeriod;
	}

	public void setBillingPeriod(String billingPeriod) {
		this.billingPeriod = billingPeriod;
	}

	public Integer getTrialDays() {
		return trialDays;
	}

	public void setTrialDays(Integer trialDays) {
		this.trialDays = trialDays;
	}

	public Boolean getIsDefault() {
		return isDefault;
	}

	public void setIsDefault(Boolean isDefault) {
		this.isDefault = isDefault;
	}

	public String getRole() {
		return role;
	}

	public void setRole(String role) {
		this.role = role;
	}

	public String getPlanKind() {
		return planKind;
	}

	public void setPlanKind(String planKind) {
		this.planKind = planKind;
	}

	public List<String> getModuleCodes() {
		return moduleCodes;
	}

	public void setModuleCodes(List<String> moduleCodes) {
		this.moduleCodes = moduleCodes != null ? moduleCodes : new ArrayList<>();
	}
}
