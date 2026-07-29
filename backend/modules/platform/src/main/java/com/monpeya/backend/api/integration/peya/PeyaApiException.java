package com.monpeya.backend.api.integration.peya;

public class PeyaApiException extends RuntimeException {

	private final String apiCode;

	public PeyaApiException(String message) {
		super(message);
		this.apiCode = null;
	}

	public PeyaApiException(String message, String apiCode) {
		super(message);
		this.apiCode = apiCode;
	}

	public String getApiCode() {
		return apiCode;
	}
}
