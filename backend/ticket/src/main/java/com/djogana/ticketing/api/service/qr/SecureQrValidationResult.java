package com.djogana.ticketing.api.service.qr;

import lombok.Getter;

@Getter
public class SecureQrValidationResult {

	private final boolean valid;
	private final String ticketCode;
	private final String errorMessage;
	private final boolean expired;

	private SecureQrValidationResult(boolean valid, String ticketCode, String errorMessage, boolean expired) {
		this.valid = valid;
		this.ticketCode = ticketCode;
		this.errorMessage = errorMessage;
		this.expired = expired;
	}

	public static SecureQrValidationResult ok(String ticketCode) {
		return new SecureQrValidationResult(true, ticketCode, null, false);
	}

	public static SecureQrValidationResult invalid(String message) {
		return new SecureQrValidationResult(false, null, message, false);
	}

	public static SecureQrValidationResult expired(String ticketCode) {
		return new SecureQrValidationResult(false, ticketCode, "QR code expired", true);
	}
}
