package com.djogana.ticketing.api.service;

/**
 * Placeholder stored in {@code T_TICKET.QR_PAYLOAD} — actual QR is generated on Flutter
 * ({@code SecureQRGenerator}) and validated server-side via {@link com.djogana.ticketing.api.service.qr.SecureQrValidatorService}.
 */
public final class TicketQrConstants {

	public static final String CLIENT_GENERATED = "CLIENT_QR";

	private TicketQrConstants() {
	}
}
