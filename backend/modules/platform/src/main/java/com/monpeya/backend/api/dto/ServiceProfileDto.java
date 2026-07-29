package com.monpeya.backend.api.dto;

import java.util.ArrayList;
import java.util.List;

public class ServiceProfileDto {
	private String moduleCode;
	private String moduleName;
	private String roleModel;
	private String currentRole;
	private String businessStatus;
	private String upgradePath;
	private Boolean isPeyapayMerchant;
	private Boolean canUpgradeToBusiness;
	private Boolean canSubscribeAsClient;
	private Boolean canSubscribeAsBusiness;
	private Boolean isDeplafonne;
	private Boolean needsDeplafonnementRequest;
	private List<BusinessDocumentDto> documents = new ArrayList<>();

	public String getModuleCode() {
		return moduleCode;
	}

	public void setModuleCode(String moduleCode) {
		this.moduleCode = moduleCode;
	}

	public String getModuleName() {
		return moduleName;
	}

	public void setModuleName(String moduleName) {
		this.moduleName = moduleName;
	}

	public String getRoleModel() {
		return roleModel;
	}

	public void setRoleModel(String roleModel) {
		this.roleModel = roleModel;
	}

	public String getCurrentRole() {
		return currentRole;
	}

	public void setCurrentRole(String currentRole) {
		this.currentRole = currentRole;
	}

	public String getBusinessStatus() {
		return businessStatus;
	}

	public void setBusinessStatus(String businessStatus) {
		this.businessStatus = businessStatus;
	}

	public String getUpgradePath() {
		return upgradePath;
	}

	public void setUpgradePath(String upgradePath) {
		this.upgradePath = upgradePath;
	}

	public Boolean getIsPeyapayMerchant() {
		return isPeyapayMerchant;
	}

	public void setIsPeyapayMerchant(Boolean isPeyapayMerchant) {
		this.isPeyapayMerchant = isPeyapayMerchant;
	}

	public Boolean getCanUpgradeToBusiness() {
		return canUpgradeToBusiness;
	}

	public void setCanUpgradeToBusiness(Boolean canUpgradeToBusiness) {
		this.canUpgradeToBusiness = canUpgradeToBusiness;
	}

	public Boolean getCanSubscribeAsClient() {
		return canSubscribeAsClient;
	}

	public void setCanSubscribeAsClient(Boolean canSubscribeAsClient) {
		this.canSubscribeAsClient = canSubscribeAsClient;
	}

	public Boolean getCanSubscribeAsBusiness() {
		return canSubscribeAsBusiness;
	}

	public void setCanSubscribeAsBusiness(Boolean canSubscribeAsBusiness) {
		this.canSubscribeAsBusiness = canSubscribeAsBusiness;
	}

	public Boolean getIsDeplafonne() {
		return isDeplafonne;
	}

	public void setIsDeplafonne(Boolean isDeplafonne) {
		this.isDeplafonne = isDeplafonne;
	}

	public Boolean getNeedsDeplafonnementRequest() {
		return needsDeplafonnementRequest;
	}

	public void setNeedsDeplafonnementRequest(Boolean needsDeplafonnementRequest) {
		this.needsDeplafonnementRequest = needsDeplafonnementRequest;
	}

	public List<BusinessDocumentDto> getDocuments() {
		return documents;
	}

	public void setDocuments(List<BusinessDocumentDto> documents) {
		this.documents = documents != null ? documents : new ArrayList<>();
	}

	public static class BusinessDocumentDto {
		private Long documentId;
		private String docType;
		private String fileRef;
		private String status;

		public Long getDocumentId() {
			return documentId;
		}

		public void setDocumentId(Long documentId) {
			this.documentId = documentId;
		}

		public String getDocType() {
			return docType;
		}

		public void setDocType(String docType) {
			this.docType = docType;
		}

		public String getFileRef() {
			return fileRef;
		}

		public void setFileRef(String fileRef) {
			this.fileRef = fileRef;
		}

		public String getStatus() {
			return status;
		}

		public void setStatus(String status) {
			this.status = status;
		}
	}
}
