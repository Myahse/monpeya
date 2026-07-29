package com.monpeya.backend.api.dto;

public class AccessDecisionDto {
	private Boolean allowed;
	private String requiredLevel;
	private String reason;
	private String moduleCode;
	private String actionCode;
	private Boolean authenticated;
	private Boolean hasActiveSubscription;
	private String planCode;
	private String requiredRole;
	private String userRole;

	public Boolean getAllowed() {
		return allowed;
	}

	public void setAllowed(Boolean allowed) {
		this.allowed = allowed;
	}

	public String getRequiredLevel() {
		return requiredLevel;
	}

	public void setRequiredLevel(String requiredLevel) {
		this.requiredLevel = requiredLevel;
	}

	public String getReason() {
		return reason;
	}

	public void setReason(String reason) {
		this.reason = reason;
	}

	public String getModuleCode() {
		return moduleCode;
	}

	public void setModuleCode(String moduleCode) {
		this.moduleCode = moduleCode;
	}

	public String getActionCode() {
		return actionCode;
	}

	public void setActionCode(String actionCode) {
		this.actionCode = actionCode;
	}

	public Boolean getAuthenticated() {
		return authenticated;
	}

	public void setAuthenticated(Boolean authenticated) {
		this.authenticated = authenticated;
	}

	public Boolean getHasActiveSubscription() {
		return hasActiveSubscription;
	}

	public void setHasActiveSubscription(Boolean hasActiveSubscription) {
		this.hasActiveSubscription = hasActiveSubscription;
	}

	public String getPlanCode() {
		return planCode;
	}

	public void setPlanCode(String planCode) {
		this.planCode = planCode;
	}

	public String getRequiredRole() {
		return requiredRole;
	}

	public void setRequiredRole(String requiredRole) {
		this.requiredRole = requiredRole;
	}

	public String getUserRole() {
		return userRole;
	}

	public void setUserRole(String userRole) {
		this.userRole = userRole;
	}
}
