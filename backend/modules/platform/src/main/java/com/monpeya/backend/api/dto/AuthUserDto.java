package com.monpeya.backend.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public class AuthUserDto {
	private Long userId;
	private String phone;
	private String codeClient;
	private String nomClient;
	private String email;
	private String accountId;
	private String peyaStatus;
	private Boolean isPeyaClient;
	/** True when Peya datasCompte has typcpt=S (supplier / merchant). */
	private Boolean isPeyapayMerchant;
	/** Peya deplafonner — required for CLIENT straight subscribe debit. */
	private Boolean isDeplafonne;
	private String status;
	private String displayName;
	private String firstName;
	private String lastName;
	private LocalDate birthDate;
	private String idNumber;
	private String adresse;
	private String profession;
	private String lieuNaissance;
	private String codePaysResidence;
	private String loginClient;
	private String codeBanque;
	private String numerocomptecomplet;
	private BigDecimal soldeDispo;
	private String kycStatus;

	public Long getUserId() {
		return userId;
	}

	public void setUserId(Long userId) {
		this.userId = userId;
	}

	public String getPhone() {
		return phone;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public String getCodeClient() {
		return codeClient;
	}

	public void setCodeClient(String codeClient) {
		this.codeClient = codeClient;
	}

	public String getNomClient() {
		return nomClient;
	}

	public void setNomClient(String nomClient) {
		this.nomClient = nomClient;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getAccountId() {
		return accountId;
	}

	public void setAccountId(String accountId) {
		this.accountId = accountId;
	}

	public String getPeyaStatus() {
		return peyaStatus;
	}

	public void setPeyaStatus(String peyaStatus) {
		this.peyaStatus = peyaStatus;
	}

	public Boolean getIsPeyaClient() {
		return isPeyaClient;
	}

	public void setIsPeyaClient(Boolean isPeyaClient) {
		this.isPeyaClient = isPeyaClient;
	}

	public Boolean getIsPeyapayMerchant() {
		return isPeyapayMerchant;
	}

	public void setIsPeyapayMerchant(Boolean isPeyapayMerchant) {
		this.isPeyapayMerchant = isPeyapayMerchant;
	}

	public Boolean getIsDeplafonne() {
		return isDeplafonne;
	}

	public void setIsDeplafonne(Boolean isDeplafonne) {
		this.isDeplafonne = isDeplafonne;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public String getDisplayName() {
		return displayName;
	}

	public void setDisplayName(String displayName) {
		this.displayName = displayName;
	}

	public String getFirstName() {
		return firstName;
	}

	public void setFirstName(String firstName) {
		this.firstName = firstName;
	}

	public String getLastName() {
		return lastName;
	}

	public void setLastName(String lastName) {
		this.lastName = lastName;
	}

	public LocalDate getBirthDate() {
		return birthDate;
	}

	public void setBirthDate(LocalDate birthDate) {
		this.birthDate = birthDate;
	}

	public String getIdNumber() {
		return idNumber;
	}

	public void setIdNumber(String idNumber) {
		this.idNumber = idNumber;
	}

	public String getAdresse() {
		return adresse;
	}

	public void setAdresse(String adresse) {
		this.adresse = adresse;
	}

	public String getProfession() {
		return profession;
	}

	public void setProfession(String profession) {
		this.profession = profession;
	}

	public String getLieuNaissance() {
		return lieuNaissance;
	}

	public void setLieuNaissance(String lieuNaissance) {
		this.lieuNaissance = lieuNaissance;
	}

	public String getCodePaysResidence() {
		return codePaysResidence;
	}

	public void setCodePaysResidence(String codePaysResidence) {
		this.codePaysResidence = codePaysResidence;
	}

	public String getLoginClient() {
		return loginClient;
	}

	public void setLoginClient(String loginClient) {
		this.loginClient = loginClient;
	}

	public String getCodeBanque() {
		return codeBanque;
	}

	public void setCodeBanque(String codeBanque) {
		this.codeBanque = codeBanque;
	}

	public String getNumerocomptecomplet() {
		return numerocomptecomplet;
	}

	public void setNumerocomptecomplet(String numerocomptecomplet) {
		this.numerocomptecomplet = numerocomptecomplet;
	}

	public BigDecimal getSoldeDispo() {
		return soldeDispo;
	}

	public void setSoldeDispo(BigDecimal soldeDispo) {
		this.soldeDispo = soldeDispo;
	}

	public String getKycStatus() {
		return kycStatus;
	}

	public void setKycStatus(String kycStatus) {
		this.kycStatus = kycStatus;
	}
}
