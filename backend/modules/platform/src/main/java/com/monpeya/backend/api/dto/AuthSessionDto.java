package com.monpeya.backend.api.dto;

import java.time.LocalDateTime;

public class AuthSessionDto {
	private String accessToken;
	private String refreshToken;
	private LocalDateTime expiresAt;
	private LocalDateTime refreshExpiresAt;
	private AuthUserDto user;
	private Boolean knownPeyaClient;
	private Boolean otpRequired;

	public String getAccessToken() {
		return accessToken;
	}

	public void setAccessToken(String accessToken) {
		this.accessToken = accessToken;
	}

	public String getRefreshToken() {
		return refreshToken;
	}

	public void setRefreshToken(String refreshToken) {
		this.refreshToken = refreshToken;
	}

	public LocalDateTime getExpiresAt() {
		return expiresAt;
	}

	public void setExpiresAt(LocalDateTime expiresAt) {
		this.expiresAt = expiresAt;
	}

	public LocalDateTime getRefreshExpiresAt() {
		return refreshExpiresAt;
	}

	public void setRefreshExpiresAt(LocalDateTime refreshExpiresAt) {
		this.refreshExpiresAt = refreshExpiresAt;
	}

	public AuthUserDto getUser() {
		return user;
	}

	public void setUser(AuthUserDto user) {
		this.user = user;
	}

	public Boolean getKnownPeyaClient() {
		return knownPeyaClient;
	}

	public void setKnownPeyaClient(Boolean knownPeyaClient) {
		this.knownPeyaClient = knownPeyaClient;
	}

	public Boolean getOtpRequired() {
		return otpRequired;
	}

	public void setOtpRequired(Boolean otpRequired) {
		this.otpRequired = otpRequired;
	}
}
