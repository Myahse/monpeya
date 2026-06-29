package com.djogana.ticketing.api.integration.peya;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.Map;
import java.util.concurrent.TimeUnit;

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

@Service
public class PeyaApiClient {

	private static final Logger log = LoggerFactory.getLogger(PeyaApiClient.class);
	private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");

	private final ObjectMapper objectMapper = new ObjectMapper();
	private final OkHttpClient httpClient;

	@Value("${peya.api.enabled:true}")
	private boolean enabled;

	@Value("${peya.api.base-url:https://test1-pey-peya.djogana-pay.com}")
	private String baseUrl;

	@Value("${peya.api.token-endpoint:/authclient/token}")
	private String tokenEndpoint;

	@Value("${peya.api.admin-username:}")
	private String adminUsername;

	@Value("${peya.api.admin-password:}")
	private String adminPassword;

	@Value("${peya.api.code-pays-residence:CI}")
	private String codePaysResidence;

	@Value("${peya.api.encrypt-payloads:true}")
	private boolean encryptPayloads;

	private final PeyaCryptoClient peyaCryptoClient;

	private volatile String cachedBearerToken;

	public PeyaApiClient(PeyaCryptoClient peyaCryptoClient) {
		this.peyaCryptoClient = peyaCryptoClient;
		this.httpClient = UnsafeOkHttpClient.getUnsafeOkHttpClient().newBuilder()
				.connectTimeout(30, TimeUnit.SECONDS)
				.readTimeout(30, TimeUnit.SECONDS)
				.writeTimeout(30, TimeUnit.SECONDS)
				.build();
	}

	public boolean isEnabled() {
		return enabled;
	}

	public PeyaClientInfo searchClient(String codeClient) {
		if (!enabled) {
			throw new PeyaApiException("Peya API client lookup is disabled (peya.api.enabled=false)");
		}
		String token = obtainAdminToken();
		String codeClientPayload = encryptPayloads
				? peyaCryptoClient.encryptForApi(codeClient, "codeClient")
				: codeClient;
		Map<String, Object> body = Map.of("data", Map.of("codeClient", codeClientPayload));

		try {
			String json = postJson(baseUrl + "/wClients/rechercheclient", body, token, !encryptPayloads);
			return mapClientFromResponse(json, codeClient);
		} catch (IOException e) {
			throw new PeyaApiException("Peya rechercheclient failed: " + e.getMessage());
		}
	}

	private synchronized String obtainAdminToken() {
		if (cachedBearerToken != null && !cachedBearerToken.isBlank()) {
			return cachedBearerToken;
		}
		if (adminUsername == null || adminUsername.isBlank() || adminPassword == null || adminPassword.isBlank()) {
			throw new PeyaApiException("Peya admin credentials missing (peya.api.admin-username / admin-password)");
		}

		Map<String, Object> authBody = Map.of(
				"username", adminUsername,
				"password", adminPassword,
				"codePaysResidence", codePaysResidence);

		try {
			String json = postJson(baseUrl + tokenEndpoint, authBody, null, false);
			Map<String, Object> envelope = objectMapper.readValue(json, new TypeReference<>() {
			});
			if (Boolean.TRUE.equals(envelope.get("hasError"))) {
				throw apiError(envelope, "Peya authentication failed");
			}
			@SuppressWarnings("unchecked")
			Map<String, Object> item = (Map<String, Object>) envelope.get("item");
			if (item == null) {
				throw new PeyaApiException("Peya authentication failed: token item missing");
			}
			Object token = item.get("token");
			if (token == null || token.toString().isBlank()) {
				throw new PeyaApiException("Peya authentication failed: JWT token missing");
			}
			cachedBearerToken = token.toString();
			log.info("Peya admin JWT obtained via {}", tokenEndpoint);
			return cachedBearerToken;
		} catch (IOException e) {
			throw new PeyaApiException("Peya authentication failed: " + e.getMessage());
		}
	}

	private PeyaClientInfo mapClientFromResponse(String json, String requestedCodeClient) throws IOException {
		Map<String, Object> envelope = objectMapper.readValue(json, new TypeReference<>() {
		});
		if (Boolean.TRUE.equals(envelope.get("hasError"))) {
			throw apiError(envelope, "Peya client not found");
		}

		@SuppressWarnings("unchecked")
		Map<String, Object> item = (Map<String, Object>) envelope.get("item");
		@SuppressWarnings("unchecked")
		java.util.List<Map<String, Object>> items = (java.util.List<Map<String, Object>>) envelope.get("items");

		Map<String, Object> clientJson = item;
		if (clientJson == null && items != null && !items.isEmpty()) {
			clientJson = items.get(0);
		}
		if (clientJson == null) {
			throw new PeyaApiException("Peya client not found: codeClient=" + requestedCodeClient);
		}

		PeyaClientInfo info = new PeyaClientInfo();
		info.setCodeClient(stringVal(clientJson.get("codeClient"), requestedCodeClient));
		info.setNomClient(stringVal(clientJson.get("nomClient"), null));
		info.setGsmPrincipale(stringVal(clientJson.get("gsmPrincipale"), null));
		info.setEmail(stringVal(clientJson.get("email"), null));
		info.setLogin(firstNonBlank(
				stringVal(clientJson.get("login"), null),
				stringVal(clientJson.get("loginClient"), null)));
		info.setCodeBanque(stringVal(clientJson.get("codeBanque"), null));

		@SuppressWarnings("unchecked")
		Map<String, Object> nestedClient = (Map<String, Object>) clientJson.get("wclients");
		if (nestedClient != null) {
			if (info.getNomClient() == null) {
				info.setNomClient(stringVal(nestedClient.get("nomClient"), null));
			}
			if (info.getGsmPrincipale() == null) {
				info.setGsmPrincipale(stringVal(nestedClient.get("gsmPrincipale"), null));
			}
			if (info.getEmail() == null) {
				info.setEmail(stringVal(nestedClient.get("email"), null));
			}
			info.setAccountId(stringVal(nestedClient.get("accoundId"), info.getAccountId()));
		}

		@SuppressWarnings("unchecked")
		java.util.List<Map<String, Object>> comptes = (java.util.List<Map<String, Object>>) clientJson.get("datasCompte");
		if (comptes != null && !comptes.isEmpty()) {
			Map<String, Object> compte = comptes.get(0);
			info.setNumerocomptecomplet(stringVal(compte.get("numerocomptecomplet"), null));
			info.setSoldeDispo(decimalVal(compte.get("soldedispo")));
			if (info.getCodeBanque() == null) {
				info.setCodeBanque(stringVal(compte.get("codeBanque"), null));
			}
		}

		return info;
	}

	private String postJson(String url, Map<String, Object> body, String bearerToken, boolean noEncrypt)
			throws IOException {
		String payload = objectMapper.writeValueAsString(body);
		Request.Builder builder = new Request.Builder()
				.url(url)
				.post(RequestBody.create(payload, JSON))
				.header("Content-Type", "application/json")
				.header("Accept", "application/json");
		if (noEncrypt) {
			builder.header("no-encrypt", "true");
		}
		if (bearerToken != null) {
			builder.header("Authorization", "Bearer " + bearerToken);
		}

		try (Response response = httpClient.newCall(builder.build()).execute()) {
			String responseBody = response.body() != null ? response.body().string() : "";
			if (!response.isSuccessful()) {
				throw new PeyaApiException("HTTP " + response.code() + " from " + url + ": " + responseBody);
			}
			return responseBody;
		}
	}

	private static PeyaApiException apiError(Map<String, Object> envelope, String fallback) {
		@SuppressWarnings("unchecked")
		Map<String, Object> status = (Map<String, Object>) envelope.get("status");
		String code = status != null ? stringVal(status.get("code"), null) : null;
		String message = status != null ? stringVal(status.get("message"), fallback) : fallback;
		return new PeyaApiException(message, code);
	}

	private static String stringVal(Object value, String fallback) {
		if (value == null) {
			return fallback;
		}
		String s = value.toString().trim();
		return s.isEmpty() ? fallback : s;
	}

	private static String firstNonBlank(String a, String b) {
		if (a != null && !a.isBlank()) {
			return a;
		}
		return b;
	}

	private static BigDecimal decimalVal(Object value) {
		if (value == null) {
			return null;
		}
		if (value instanceof BigDecimal bd) {
			return bd;
		}
		if (value instanceof Number n) {
			return BigDecimal.valueOf(n.doubleValue());
		}
		try {
			return new BigDecimal(value.toString());
		} catch (NumberFormatException e) {
			return null;
		}
	}
}
