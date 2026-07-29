package com.monpeya.backend.api.dto;

public class AuthPhoneDto {
	private String phone;
	private String residenceCountry;
	private String imei;
	private String modele;
	private String platform;
	private String pin;
	private String otpCode;
	private String refreshToken;
	private String accessToken;

	public String getPhone() {
		return phone;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public String getResidenceCountry() {
		return residenceCountry;
	}

	public void setResidenceCountry(String residenceCountry) {
		this.residenceCountry = residenceCountry;
	}

	public String getImei() {
		return imei;
	}

	public void setImei(String imei) {
		this.imei = imei;
	}

	public String getModele() {
		return modele;
	}

	public void setModele(String modele) {
		this.modele = modele;
	}

	public String getPlatform() {
		return platform;
	}

	public void setPlatform(String platform) {
		this.platform = platform;
	}

	public String getPin() {
		return pin;
	}

	public void setPin(String pin) {
		this.pin = pin;
	}

	public String getOtpCode() {
		return otpCode;
	}

	public void setOtpCode(String otpCode) {
		this.otpCode = otpCode;
	}

	public String getRefreshToken() {
		return refreshToken;
	}

	public void setRefreshToken(String refreshToken) {
		this.refreshToken = refreshToken;
	}

	public String getAccessToken() {
		return accessToken;
	}

	public void setAccessToken(String accessToken) {
		this.accessToken = accessToken;
	}
}
