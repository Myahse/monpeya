package com.monpeya.backend.api.dto;

public class SubscribeDto {
	private String accessToken;
	private String planCode;
	/** Service to unlock (required for dual-role products). */
	private String moduleCode;
	/** CLIENT (use tickets) | BUSINESS (conductor / owner). Default CLIENT. */
	private String role;

	public String getAccessToken() {
		return accessToken;
	}

	public void setAccessToken(String accessToken) {
		this.accessToken = accessToken;
	}

	public String getPlanCode() {
		return planCode;
	}

	public void setPlanCode(String planCode) {
		this.planCode = planCode;
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
}
