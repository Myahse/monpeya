package com.monpeya.backend.api.dto;

import java.time.LocalDateTime;

public class SubscriptionDto {
	private Long subscriptionId;
	private String moduleCode;
	private String role;
	private String planCode;
	private String planName;
	private String status;
	private LocalDateTime startAt;
	private LocalDateTime endAt;
	private LocalDateTime trialEndAt;
	private Boolean autoRenew;
	private String paymentProvider;
	private String paymentStatus;
	private String paymentRef;
	private Boolean isMockPayment;

	public Long getSubscriptionId() {
		return subscriptionId;
	}

	public void setSubscriptionId(Long subscriptionId) {
		this.subscriptionId = subscriptionId;
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

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public LocalDateTime getStartAt() {
		return startAt;
	}

	public void setStartAt(LocalDateTime startAt) {
		this.startAt = startAt;
	}

	public LocalDateTime getEndAt() {
		return endAt;
	}

	public void setEndAt(LocalDateTime endAt) {
		this.endAt = endAt;
	}

	public LocalDateTime getTrialEndAt() {
		return trialEndAt;
	}

	public void setTrialEndAt(LocalDateTime trialEndAt) {
		this.trialEndAt = trialEndAt;
	}

	public Boolean getAutoRenew() {
		return autoRenew;
	}

	public void setAutoRenew(Boolean autoRenew) {
		this.autoRenew = autoRenew;
	}

	public String getPaymentProvider() {
		return paymentProvider;
	}

	public void setPaymentProvider(String paymentProvider) {
		this.paymentProvider = paymentProvider;
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
}
