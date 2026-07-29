package com.monpeya.backend.api.dto;

public class ServiceProfileRequestDto {
	private String accessToken;
	private String moduleCode;
	/** DOCUMENTS | PEYAPAY_MERCHANT */
	private String upgradePath;
	private Boolean isPeyapayMerchant;
	/** ID_CARD_FRONT | ID_CARD_BACK | BUSINESS_REG | OTHER */
	private String docType;
	private String fileRef;

	public String getAccessToken() {
		return accessToken;
	}

	public void setAccessToken(String accessToken) {
		this.accessToken = accessToken;
	}

	public String getModuleCode() {
		return moduleCode;
	}

	public void setModuleCode(String moduleCode) {
		this.moduleCode = moduleCode;
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
}
