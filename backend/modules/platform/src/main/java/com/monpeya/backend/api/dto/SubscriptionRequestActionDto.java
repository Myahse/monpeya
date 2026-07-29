package com.monpeya.backend.api.dto;

import java.math.BigDecimal;

public class SubscriptionRequestActionDto {
	private String accessToken;
	private Long requestId;
	/** BUSINESS_SUBSCRIBE | DEPLAFONNEMENT */
	private String requestType;
	private String moduleCode;
	private String planCode;
	private String role;
	/** Optional override; defaults to plan price. */
	private BigDecimal amount;
	/** APPROVE | REJECT | ON_REVIEW */
	private String decision;
	private String reviewNote;

	public String getAccessToken() {
		return accessToken;
	}

	public void setAccessToken(String accessToken) {
		this.accessToken = accessToken;
	}

	public Long getRequestId() {
		return requestId;
	}

	public void setRequestId(Long requestId) {
		this.requestId = requestId;
	}

	public String getRequestType() {
		return requestType;
	}

	public void setRequestType(String requestType) {
		this.requestType = requestType;
	}

	public String getModuleCode() {
		return moduleCode;
	}

	public void setModuleCode(String moduleCode) {
		this.moduleCode = moduleCode;
	}

	public String getPlanCode() {
		return planCode;
	}

	public void setPlanCode(String planCode) {
		this.planCode = planCode;
	}

	public String getRole() {
		return role;
	}

	public void setRole(String role) {
		this.role = role;
	}

	public BigDecimal getAmount() {
		return amount;
	}

	public void setAmount(BigDecimal amount) {
		this.amount = amount;
	}

	public String getDecision() {
		return decision;
	}

	public void setDecision(String decision) {
		this.decision = decision;
	}

	public String getReviewNote() {
		return reviewNote;
	}

	public void setReviewNote(String reviewNote) {
		this.reviewNote = reviewNote;
	}
}
