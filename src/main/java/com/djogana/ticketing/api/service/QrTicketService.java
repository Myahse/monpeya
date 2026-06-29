package com.djogana.ticketing.api.service;

import java.nio.charset.StandardCharsets;
import java.util.HexFormat;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class QrTicketService {

	private static final Logger log = LoggerFactory.getLogger(QrTicketService.class);
	private static final String PREFIX = "TKT";
	private static final int MIN_KEY_LENGTH = 32;

	private final String secret;

	public QrTicketService(@Value("${ticketing.qr.secret}") String secret) {
		this.secret = secret != null ? secret.trim() : "";
		if (this.secret.length() < MIN_KEY_LENGTH) {
			log.warn("ticketing.qr.secret / QR_ENCRYPT_KEY is missing or shorter than {} chars — QR signatures are weak",
					MIN_KEY_LENGTH);
		} else {
			log.info("QR HMAC configured ({} chars, Mon peya QR_ENCRYPT_KEY parity)", this.secret.length());
		}
	}

	/** QR format: TKT|{ticketCode}|{contextRef}|{hmac} */
	public String buildPayload(String ticketCode, String contextRef) {
		String ref = contextRef != null ? contextRef : "";
		String signature = sign(ticketCode + "|" + ref);
		return PREFIX + "|" + ticketCode + "|" + ref + "|" + signature;
	}

	public boolean isValid(String qrPayload) {
		if (qrPayload == null || qrPayload.isBlank()) {
			return false;
		}
		String[] parts = qrPayload.split("\\|");
		if (parts.length != 4 || !PREFIX.equals(parts[0])) {
			return false;
		}
		String expected = sign(parts[1] + "|" + parts[2]);
		return expected.equals(parts[3]);
	}

	public String extractTicketCode(String qrPayload) {
		String[] parts = qrPayload.split("\\|");
		return parts.length >= 2 ? parts[1] : null;
	}

	private String sign(String payload) {
		try {
			Mac mac = Mac.getInstance("HmacSHA256");
			mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
			return HexFormat.of().formatHex(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
		} catch (Exception ex) {
			throw new IllegalStateException("QR signature failed", ex);
		}
	}
}
