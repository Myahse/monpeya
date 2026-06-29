package com.djogana.ticketing.api.service.qr;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.HexFormat;

import javax.crypto.Cipher;
import javax.crypto.Mac;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;


@Service
public class SecureQrValidatorService {

	private static final Logger log = LoggerFactory.getLogger(SecureQrValidatorService.class);
	private static final int MIN_KEY_LENGTH = 32;

	private final ObjectMapper objectMapper = new ObjectMapper();
	private final String secretKey;
	private final boolean enableEncryption;
	private final boolean enableSignature;
	private final boolean checkExpiration;
	private final long validityMillis;

	public SecureQrValidatorService(
			@Value("${ticketing.qr.secret}") String secretKey,
			@Value("${ticketing.qr.enable-encryption:true}") boolean enableEncryption,
			@Value("${ticketing.qr.enable-signature:true}") boolean enableSignature,
			@Value("${ticketing.qr.check-expiration:false}") boolean checkExpiration,
			@Value("${ticketing.qr.validity-minutes:0}") int validityMinutes) {
		this.secretKey = secretKey != null ? secretKey.trim() : "";
		this.enableEncryption = enableEncryption;
		this.enableSignature = enableSignature;
		this.checkExpiration = checkExpiration && validityMinutes > 0;
		this.validityMillis = validityMinutes * 60_000L;
		if (this.secretKey.length() < MIN_KEY_LENGTH) {
			log.warn("ticketing.qr.secret / QR_ENCRYPT_KEY shorter than {} chars", MIN_KEY_LENGTH);
		}
	}

	public SecureQrValidationResult validate(String encodedPayload) {
		if (encodedPayload == null || encodedPayload.isBlank()) {
			return SecureQrValidationResult.invalid("empty QR payload");
		}
		try {
			String json = decryptOrDecode(encodedPayload.trim());
			if (json == null) {
				return SecureQrValidationResult.invalid("decryption or decoding failed");
			}

			JsonNode root = objectMapper.readTree(json);
			if (!root.isObject()) {
				return SecureQrValidationResult.invalid("invalid payload format");
			}

			if (!hasRequiredFields(root)) {
				return SecureQrValidationResult.invalid("missing required QR fields");
			}

			if (enableSignature && !verifySignature(json, root)) {
				return SecureQrValidationResult.invalid("invalid QR signature");
			}

			long timestamp = root.get("timestamp").asLong();
			if (checkExpiration && System.currentTimeMillis() - timestamp > validityMillis) {
				String ticketCode = extractTicketCode(root);
				return SecureQrValidationResult.expired(ticketCode);
			}

			String ticketCode = extractTicketCode(root);
			if (ticketCode == null || ticketCode.isBlank()) {
				return SecureQrValidationResult.invalid("ticketCodeKey missing in QR payload");
			}
			return SecureQrValidationResult.ok(ticketCode.trim());
		} catch (Exception ex) {
			log.debug("SecureQR validation failed: {}", ex.getMessage());
			return SecureQrValidationResult.invalid("invalid QR payload");
		}
	}

	private String decryptOrDecode(String encodedPayload) {
		try {
			byte[] bytes = Base64.getDecoder().decode(encodedPayload);
			if (enableEncryption) {
				if (bytes.length <= 16) {
					return null;
				}
				byte[] iv = new byte[16];
				System.arraycopy(bytes, 0, iv, 0, 16);
				byte[] cipherBytes = new byte[bytes.length - 16];
				System.arraycopy(bytes, 16, cipherBytes, 0, cipherBytes.length);

				Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
				cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(aesKeyBytes(secretKey), "AES"), new IvParameterSpec(iv));
				return new String(cipher.doFinal(cipherBytes), StandardCharsets.UTF_8);
			}
			return new String(bytes, StandardCharsets.UTF_8);
		} catch (Exception ex) {
			return null;
		}
	}

	private boolean hasRequiredFields(JsonNode root) {
		return root.hasNonNull("data") && root.get("data").isObject()
				&& root.has("timestamp") && root.get("timestamp").canConvertToLong()
				&& root.has("version") && root.get("version").canConvertToInt()
				&& root.hasNonNull("id") && root.get("id").isTextual();
	}

	/** Verifies HMAC on the exact JSON string Dart signed (before {@code signature} was appended). */
	private boolean verifySignature(String rawJson, JsonNode root) {
		if (!root.hasNonNull("signature")) {
			return false;
		}
		String original = root.get("signature").asText();
		String unsigned = stripSignatureField(rawJson);
		String expected = hmacSha256Hex(unsigned, secretKey.getBytes(StandardCharsets.UTF_8));
		return MessageDigest.isEqual(
				original.getBytes(StandardCharsets.UTF_8),
				expected.getBytes(StandardCharsets.UTF_8));
	}

	/** Dart adds {@code signature} last — strip {@code ,"signature":"..."} to match signed bytes. */
	private static String stripSignatureField(String json) {
		int sigIdx = json.lastIndexOf("\"signature\"");
		if (sigIdx < 0) {
			return json;
		}
		int comma = json.lastIndexOf(',', sigIdx);
		if (comma < 0) {
			return json;
		}
		return json.substring(0, comma) + "}";
	}

	/** Dart {@code Hmac(sha256, utf8.encode(secretKey))} — full key, not padRight. */
	private String hmacSha256Hex(String json, byte[] keyBytes) {
		try {
			Mac mac = Mac.getInstance("HmacSHA256");
			mac.init(new SecretKeySpec(keyBytes, "HmacSHA256"));
			return HexFormat.of().formatHex(mac.doFinal(json.getBytes(StandardCharsets.UTF_8)));
		} catch (Exception ex) {
			throw new IllegalStateException("HMAC failed", ex);
		}
	}

	private String extractTicketCode(JsonNode root) {
		JsonNode data = root.get("data");
		if (data == null || !data.isObject()) {
			return null;
		}
		JsonNode payload = data.get("payload");
		if (payload == null || !payload.isObject()) {
			return null;
		}
		for (String key : new String[] { "ticketCodeKey", "ticketCode", "codeTicketKey" }) {
			JsonNode node = payload.get(key);
			if (node != null && node.isTextual() && !node.asText().isBlank()) {
				return node.asText();
			}
		}
		return null;
	}

	/** Dart: {@code Key.fromUtf8(secretKey.padRight(32))} — space-padded to 32 chars. */
	static byte[] aesKeyBytes(String secret) {
		String padded = secret.length() >= 32 ? secret.substring(0, 32) : String.format("%-32s", secret);
		return padded.getBytes(StandardCharsets.UTF_8);
	}
}
