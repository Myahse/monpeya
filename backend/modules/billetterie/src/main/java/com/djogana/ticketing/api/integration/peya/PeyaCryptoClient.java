package com.djogana.ticketing.api.integration.peya;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.djogana.ticketing.api.contracts.UnsafeOkHttpClient;

import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

/**
 * NCG field encryption — same contract as Mon peya {@code PeyapayCryptoService}.
 */
@Service("billetteriePeyaCryptoClient")
public class PeyaCryptoClient {

	private static final Logger log = LoggerFactory.getLogger(PeyaCryptoClient.class);
	private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");
	private static final Pattern BASE64_CIPHER = Pattern.compile("^[A-Za-z0-9+/]+=*$");
	private static final Pattern PLAIN_DIGITS = Pattern.compile("^\\d{1,12}$");

	private final ObjectMapper objectMapper = new ObjectMapper();
	private final OkHttpClient httpClient;

	@Value("${peya.api.crypto-url:https://djoganapayci.com/api10/peya-2.0/ncg}")
	private String cryptoBaseUrl;

	public PeyaCryptoClient() {
		this.httpClient = UnsafeOkHttpClient.getUnsafeOkHttpClient().newBuilder()
				.connectTimeout(30, TimeUnit.SECONDS)
				.readTimeout(30, TimeUnit.SECONDS)
				.writeTimeout(30, TimeUnit.SECONDS)
				.build();
	}

	public String encryptForApi(String plainText, String label) {
		String value = plainText != null ? plainText.trim() : "";
		if (value.isEmpty()) {
			throw new PeyaApiException(label + " is empty");
		}
		if (looksLikeEncrypted(value)) {
			log.debug("Peya crypto: {} already encrypted", label);
			return value;
		}

		try {
			String encrypted = encryptString(value);
			if (encrypted == null || encrypted.isBlank()) {
				throw new PeyaApiException("Failed to encrypt " + label + " (empty crypto response)");
			}
			if (!looksLikeEncrypted(encrypted)) {
				throw new PeyaApiException(
						"Failed to encrypt " + label + " — check peya.api.crypto-url (" + cryptoBaseUrl + ")");
			}
			log.debug("Peya crypto: {} encrypted", label);
			return encrypted;
		} catch (IOException e) {
			throw new PeyaApiException("Failed to encrypt " + label + ": " + e.getMessage());
		}
	}

	public static boolean looksLikeEncrypted(String value) {
		if (value == null || value.isBlank()) {
			return false;
		}
		String text = value.trim();
		if (text.startsWith("DPAY")) {
			return false;
		}
		if (PLAIN_DIGITS.matcher(text).matches()) {
			return false;
		}
		if (text.length() < 16) {
			return false;
		}
		return BASE64_CIPHER.matcher(text).matches();
	}

	private String encryptString(String plainText) throws IOException {
		String url = normalizeBaseUrl(cryptoBaseUrl) + "/crypt";
		Map<String, Object> body = Map.of("data", Map.of("string", plainText));
		String json = postJson(url, body);
		return extractStringField(json, "encryption");
	}

	private String postJson(String url, Map<String, Object> body) throws IOException {
		String payload = objectMapper.writeValueAsString(body);
		Request request = new Request.Builder()
				.url(url)
				.post(RequestBody.create(payload, JSON))
				.header("Content-Type", "application/json")
				.header("Accept", "application/json")
				.build();

		try (Response response = httpClient.newCall(request).execute()) {
			String responseBody = response.body() != null ? response.body().string() : "";
			if (!response.isSuccessful()) {
				throw new PeyaApiException("Crypto HTTP " + response.code() + ": " + responseBody);
			}
			return responseBody;
		}
	}

	private String extractStringField(String json, String operation) throws IOException {
		Map<String, Object> decoded = objectMapper.readValue(json, new TypeReference<>() {
		});
		if (Boolean.TRUE.equals(decoded.get("hasError"))) {
			@SuppressWarnings("unchecked")
			Map<String, Object> status = (Map<String, Object>) decoded.get("status");
			String message = status != null ? String.valueOf(status.get("message")) : operation + " failed";
			throw new PeyaApiException(message);
		}

		@SuppressWarnings("unchecked")
		Map<String, Object> item = (Map<String, Object>) decoded.get("item");
		if (item != null && item.get("string") != null) {
			return item.get("string").toString();
		}
		@SuppressWarnings("unchecked")
		Map<String, Object> data = (Map<String, Object>) decoded.get("data");
		if (data != null && data.get("string") != null) {
			return data.get("string").toString();
		}
		if (decoded.get("string") != null) {
			return decoded.get("string").toString();
		}
		return null;
	}

	private static String normalizeBaseUrl(String baseUrl) {
		if (baseUrl == null || baseUrl.isBlank()) {
			return "";
		}
		return baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
	}
}
