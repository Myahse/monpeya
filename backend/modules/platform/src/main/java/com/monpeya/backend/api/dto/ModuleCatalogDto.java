package com.monpeya.backend.api.dto;

import java.util.ArrayList;
import java.util.List;

public class ModuleCatalogDto {
	private String code;
	private String name;
	private String description;
	/** CLIENT_ONLY | CLIENT_AND_BUSINESS */
	private String roleModel;
	/** Key/value parameters for mobile reuse per service. */
	private List<ParamDto> parameters = new ArrayList<>();
	private String openAccessLevel;
	private String defaultActionLevel;
	private Integer sortOrder;
	private List<ServiceActionDto> actions = new ArrayList<>();

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

	public String getRoleModel() {
		return roleModel;
	}

	public void setRoleModel(String roleModel) {
		this.roleModel = roleModel;
	}

	public List<ParamDto> getParameters() {
		return parameters;
	}

	public void setParameters(List<ParamDto> parameters) {
		this.parameters = parameters != null ? parameters : new ArrayList<>();
	}

	public String getOpenAccessLevel() {
		return openAccessLevel;
	}

	public void setOpenAccessLevel(String openAccessLevel) {
		this.openAccessLevel = openAccessLevel;
	}

	public String getDefaultActionLevel() {
		return defaultActionLevel;
	}

	public void setDefaultActionLevel(String defaultActionLevel) {
		this.defaultActionLevel = defaultActionLevel;
	}

	public Integer getSortOrder() {
		return sortOrder;
	}

	public void setSortOrder(Integer sortOrder) {
		this.sortOrder = sortOrder;
	}

	public List<ServiceActionDto> getActions() {
		return actions;
	}

	public void setActions(List<ServiceActionDto> actions) {
		this.actions = actions;
	}

	public static class ParamDto {
		private String key;
		private String value;

		public ParamDto() {
		}

		public ParamDto(String key, String value) {
			this.key = key;
			this.value = value;
		}

		public String getKey() {
			return key;
		}

		public void setKey(String key) {
			this.key = key;
		}

		public String getValue() {
			return value;
		}

		public void setValue(String value) {
			this.value = value;
		}
	}

	public static class ServiceActionDto {
		private String code;
		private String name;
		private String accessLevel;
		/** ANY | CLIENT | BUSINESS */
		private String requiredRole;

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

		public String getAccessLevel() {
			return accessLevel;
		}

		public void setAccessLevel(String accessLevel) {
			this.accessLevel = accessLevel;
		}

		public String getRequiredRole() {
			return requiredRole;
		}

		public void setRequiredRole(String requiredRole) {
			this.requiredRole = requiredRole;
		}
	}
}
