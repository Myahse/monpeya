package com.monpeya.backend.api.dto;

/** Optional filter when listing plans (e.g. moduleCode=billetterie). */
public class PlansQueryDto {
	private String moduleCode;
	/** CLIENT | BUSINESS — optional hint for UI. */
	private String role;

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
