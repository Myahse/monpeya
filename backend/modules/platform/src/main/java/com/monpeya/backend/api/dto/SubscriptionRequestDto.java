package com.monpeya.backend.api.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class SubscriptionRequestDto {
	private Long requestId;
	private String requestType;
	private String moduleCode;
	private String role;
	private String planCode;
	private String planName;
	private BigDecimal amount;
	private String currency;
	private String status;
	private String paymentStatus;
	private String paymentRef;
	private Boolean isMockPayment;
	private LocalDateTime debitedAt;
	private LocalDateTime reviewedAt;
	private String reviewNote;
	private Long subscriptionId;
	private LocalDateTime createdAt;

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

	public String getRole() {
		return role;
	}

	public void setRole(String role) {
		this.role = role;
	}

	public String getPlanCode() {
		return planCode;
	}

	public void setPlanCode(String planCode) {
		this.planCode = planCode;
	}

	public String getPlanName() {
		return planName;
	}

	public void setPlanName(String planName) {
		this.planName = planName;
	}

	public BigDecimal getAmount() {
		return amount;
	}

	public void setAmount(BigDecimal amount) {
		this.amount = amount;
	}

	public String getCurrency() {
		return currency;
	}

	public void setCurrency(String currency) {
		this.currency = currency;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public String getPaymentStatus() {
		return paymentStatus;
	}

	public void setPaymentStatus(String paymentStatus) {
		this.paymentStatus = paymentStatus;
	}

	public String getPaymentRef() {
		return paymentRef;
	}

	public void setPaymentRef(String paymentRef) {
		this.paymentRef = paymentRef;
	}

	public Boolean getIsMockPayment() {
		return isMockPayment;
	}

	public void setIsMockPayment(Boolean isMockPayment) {
		this.isMockPayment = isMockPayment;
	}

	public LocalDateTime getDebitedAt() {
		return debitedAt;
	}

	public void setDebitedAt(LocalDateTime debitedAt) {
		this.debitedAt = debitedAt;
	}

	public LocalDateTime getReviewedAt() {
		return reviewedAt;
	}

	public void setReviewedAt(LocalDateTime reviewedAt) {
		this.reviewedAt = reviewedAt;
	}

	public String getReviewNote() {
		return reviewNote;
	}

	public void setReviewNote(String reviewNote) {
		this.reviewNote = reviewNote;
	}

	public Long getSubscriptionId() {
		return subscriptionId;
	}

	public void setSubscriptionId(Long subscriptionId) {
		this.subscriptionId = subscriptionId;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}
}
