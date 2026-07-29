package com.monpeya.backend.api.integration.peya;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.monpeya.backend.api.contracts.UnsafeOkHttpClient;

import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;


@Service("monpeyaPeyaApiClient")
public class PeyaApiClient {

	private static final Logger log = LoggerFactory.getLogger(PeyaApiClient.class);
	private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");

	private final ObjectMapper objectMapper = new ObjectMapper();
	private final OkHttpClient httpClient;
	private final PeyaCryptoClient peyaCryptoClient;

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

	private volatile String cachedAdminToken;

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

	public String defaultResidenceCountry() {
		return codePaysResidence;
	}

	public List<PeyaClientInfo> searchGsm(String phoneDigits) {
		ensureEnabled();
		String token = obtainAdminToken();
		Map<String, Object> data = new HashMap<>();
		data.put("gsmPrincipale", encryptIfNeeded(phoneDigits, "gsmPrincipale"));
		try {
			String json = postJson(url("/wClients/rechercheGsm"), Map.of("data", data), token, !encryptPayloads);
			return mapClientList(json);
		} catch (IOException e) {
			throw new PeyaApiException("Peya rechercheGsm failed: " + e.getMessage());
		}
	}


	public PeyaClientInfo searchClientByCode(String codeClient) {
		ensureEnabled();
		if (codeClient == null || codeClient.isBlank()) {
			throw new PeyaApiException("codeClient is empty");
		}
		String token = obtainAdminToken();
		Map<String, Object> data = new HashMap<>();
		data.put("codeClient", encryptIfNeeded(codeClient, "codeClient"));
		try {
			String json = postJson(url("/wClients/rechercheclient"), Map.of("data", data), token, !encryptPayloads);
			List<PeyaClientInfo> list = mapClientList(json);
			if (list.isEmpty()) {
				throw new PeyaApiException("Peya client not found: codeClient=" + codeClient);
			}
			PeyaClientInfo info = list.get(0);
			if (info.getCodeClient() == null || info.getCodeClient().isBlank()) {
				info.setCodeClient(codeClient);
			}
			log.info("Peya rechercheclient codeClient={} deplafonner={} merchant={} accounts={}",
					info.getCodeClient(), info.isDeplafonne(), info.isPeyapayMerchant(),
					info.getAccounts() != null ? info.getAccounts().size() : 0);
			return info;
		} catch (IOException e) {
			throw new PeyaApiException("Peya rechercheclient failed: " + e.getMessage());
		}
	}

	public void sendOtp(String phoneDigits, String residenceCountry, String imei, String modele, String platform) {
		ensureEnabled();
		String token = obtainAdminToken();
	
		String resolvedImei = firstNonBlank(imei, "MONPEYA-BACKEND");
		String resolvedModele = firstNonBlank(modele, "monpeya-backend");
		String resolvedPlatform = firstNonBlank(platform, "server");
		Map<String, Object> data = new HashMap<>();
		data.put("gsmPrincipale", encryptIfNeeded(phoneDigits, "gsmPrincipale"));
		data.put("imei", encryptIfNeeded(resolvedImei, "imei"));
		data.put("modele", encryptIfNeeded(resolvedModele, "modele"));
		data.put("plateform", encryptIfNeeded(resolvedPlatform, "plateform"));
		try {
			String json = postJson(url("/wClients/code"), Map.of("data", data), token, !encryptPayloads, true);
			assertNoError(json, "Peya OTP send failed", true);
		} catch (IOException e) {
			throw new PeyaApiException("Peya OTP send failed: " + e.getMessage());
		}
	}

	public void verifyOtp(String phoneDigits, String otpCode) {
		ensureEnabled();
		String token = obtainAdminToken();
		
		Map<String, Object> data = new HashMap<>();
		data.put("codeValid", encryptIfNeeded(otpCode, "codeValid"));
		data.put("login", encryptIfNeeded(phoneDigits, "login"));
		try {
			String json = postJson(url("/wClients/verifcode"), Map.of("data", data), token, !encryptPayloads, true);
			assertNoError(json, "Peya OTP verify failed", true);
		} catch (IOException e) {
			throw new PeyaApiException("Peya OTP verify failed: " + e.getMessage());
		}
	}

	public void verifyPin(String phoneDigits, String pin) {
		ensureEnabled();
		String token = obtainAdminToken();
		Map<String, Object> data = new HashMap<>();
		data.put("gsmPrincipale", encryptIfNeeded(phoneDigits, "gsmPrincipale"));
		data.put("codePin", encryptIfNeeded(pin, "codePin"));
		try {
			String json = postJson(url("/wClients/verifCodePin"), Map.of("data", data), token, !encryptPayloads);
			assertNoError(json, "Peya PIN verify failed");
		} catch (IOException e) {
			throw new PeyaApiException("Peya PIN verify failed: " + e.getMessage());
		}
	}

	/**
	 * Client profile/state used during auth upsert ({@code /wClients/etatclient}).
	 * Device fields are optional for server-side login; a stable backend push id is used when missing.
	 */
	public PeyaClientInfo fetchClientState(String phoneDigits, String residenceCountry,
			String imei, String modele, String platform) {
		ensureEnabled();
		String token = obtainAdminToken();
		String pushId = (imei != null && !imei.isBlank() && !"unknown".equalsIgnoreCase(imei))
				? imei
				: "MONPEYA-BACKEND";
		Map<String, Object> data = new HashMap<>();
		data.put("gsmPrincipale", encryptIfNeeded(phoneDigits, "gsmPrincipale"));
		data.put("codePaysResidence", residenceCountry != null && !residenceCountry.isBlank()
				? residenceCountry
				: codePaysResidence);
		data.put("identifiantPush", pushId);
		data.put("imei", pushId);
		data.put("modele", modele != null && !modele.isBlank() ? modele : "monpeya-backend");
		data.put("plateform", platform != null && !platform.isBlank() ? platform : "server");
		try {
			String json = postJson(url("/wClients/etatclient"), Map.of("data", data), token, !encryptPayloads);
			Map<String, Object> envelope = objectMapper.readValue(json, new TypeReference<>() {
			});
			if (Boolean.TRUE.equals(envelope.get("hasError"))) {
				throw apiError(envelope, "Peya etatclient failed");
			}
			@SuppressWarnings("unchecked")
			Map<String, Object> item = (Map<String, Object>) envelope.get("item");
			if (item == null) {
				throw new PeyaApiException("Peya etatclient failed: item missing");
			}
			PeyaClientInfo info = mapClient(item);
			info.setGsmPrincipale(firstNonBlank(info.getGsmPrincipale(), phoneDigits));
			info.setEtatClient(stringVal(item.get("etatClient"), info.getEtatClient()));
			info.setCodePaysResidence(stringVal(item.get("codePaysResidence"), codePaysResidence));
			info.setAccountId(firstNonBlank(
					info.getAccountId(),
					stringVal(item.get("accountId"), null),
					stringVal(item.get("accoundId"), null)));
			return info;
		} catch (IOException e) {
			throw new PeyaApiException("Peya etatclient failed: " + e.getMessage());
		}
	}

	/** Client wallet JWT — same as Flutter {@code loginClientWallet}. */
	public String loginClientToken(String phoneDigits, String pin, String residenceCountry) {
		ensureEnabled();
		String username = encryptIfNeeded(phoneDigits, "gsmPrincipale");
		String password = encryptIfNeeded(pin, "codePin");
		Map<String, Object> authBody = Map.of(
				"username", username,
				"password", password,
				"codePaysResidence", residenceCountry != null && !residenceCountry.isBlank()
						? residenceCountry
						: codePaysResidence);
		try {
			String json = postJson(url(tokenEndpoint), authBody, null, false);
			return extractToken(json, "Peya client authentication failed");
		} catch (IOException e) {
			throw new PeyaApiException("Peya client authentication failed: " + e.getMessage());
		}
	}

	/**
	 * Flutter parity: after {@code verifCodePin}, try client JWT; on apiCode 919
	 * (or equivalent login/password refusal) continue with admin bearer.
	 */
	public String loginClientTokenOrAdminFallback(String phoneDigits, String pin, String residenceCountry) {
		try {
			return loginClientToken(phoneDigits, pin, residenceCountry);
		} catch (PeyaApiException ex) {
			if (isClientJwtRefused(ex)) {
				log.warn("Peya client JWT refused (code={}): {} — falling back to admin token",
						ex.getApiCode(), ex.getMessage());
				return obtainAdminToken();
			}
			throw ex;
		}
	}

	private static boolean isClientJwtRefused(PeyaApiException ex) {
		if ("919".equals(ex.getApiCode())) {
			return true;
		}
		String msg = ex.getMessage() != null ? ex.getMessage().toLowerCase() : "";
		return msg.contains("login et/ou mot de passe")
				|| msg.contains("login and/or password");
	}

	public synchronized String obtainAdminToken() {
		if (cachedAdminToken != null && !cachedAdminToken.isBlank()) {
			return cachedAdminToken;
		}
		if (adminUsername == null || adminUsername.isBlank() || adminPassword == null || adminPassword.isBlank()) {
			throw new PeyaApiException("Peya admin credentials missing (PEYA_APP_ADMIN_USERNAME / PEYA_APP_ADMIN_PASSWORD)");
		}
		Map<String, Object> authBody = Map.of(
				"username", adminUsername,
				"password", adminPassword,
				"codePaysResidence", codePaysResidence);
		try {
			String json = postJson(url(tokenEndpoint), authBody, null, false);
			cachedAdminToken = extractToken(json, "Peya admin authentication failed");
			log.info("Peya admin JWT obtained via {}", tokenEndpoint);
			return cachedAdminToken;
		} catch (IOException e) {
			throw new PeyaApiException("Peya admin authentication failed: " + e.getMessage());
		}
	}

	private List<PeyaClientInfo> mapClientList(String json) throws IOException {
		Map<String, Object> envelope = objectMapper.readValue(json, new TypeReference<>() {
		});
		if (Boolean.TRUE.equals(envelope.get("hasError"))) {
			// Unknown phone is a normal branch for onboarding — return empty, not exception.
			return List.of();
		}
		List<PeyaClientInfo> result = new ArrayList<>();
		@SuppressWarnings("unchecked")
		List<Map<String, Object>> items = (List<Map<String, Object>>) envelope.get("items");
		if (items != null) {
			for (Map<String, Object> item : items) {
				result.add(mapClient(item));
			}
		}
		@SuppressWarnings("unchecked")
		Map<String, Object> item = (Map<String, Object>) envelope.get("item");
		if (result.isEmpty() && item != null) {
			result.add(mapClient(item));
		}
		return result;
	}

	private PeyaClientInfo mapClient(Map<String, Object> clientJson) {
		PeyaClientInfo info = new PeyaClientInfo();
		applyClientFields(info, clientJson);

		@SuppressWarnings("unchecked")
		Map<String, Object> nestedRoot = (Map<String, Object>) clientJson.get("wclients");
		if (nestedRoot != null) {
			applyClientFields(info, nestedRoot);
		}

		@SuppressWarnings("unchecked")
		List<Map<String, Object>> comptes = (List<Map<String, Object>>) clientJson.get("datasCompte");
		if (comptes != null && !comptes.isEmpty()) {
			List<PeyaAccountInfo> accounts = new ArrayList<>();
			boolean hasSupplierAccount = false;
			PeyaAccountInfo principalAccount = null;
			for (int i = 0; i < comptes.size(); i++) {
				Map<String, Object> compte = comptes.get(i);
				PeyaAccountInfo account = mapAccount(compte);
				accounts.add(account);
				if ("S".equalsIgnoreCase(account.getTypeCompte())) {
					hasSupplierAccount = true;
				}
				if (principalAccount == null && "P".equalsIgnoreCase(account.getTypeCompte())) {
					principalAccount = account;
				}
				@SuppressWarnings("unchecked")
				Map<String, Object> nestedCompteClient = (Map<String, Object>) compte.get("wclients");
				if (nestedCompteClient != null) {
					applyClientFields(info, nestedCompteClient);
				}
			}
			if (principalAccount == null && !accounts.isEmpty()) {
				principalAccount = accounts.get(0);
			}
			if (principalAccount != null) {
				principalAccount.setPrincipal(true);
				info.setNumerocomptecomplet(firstNonBlank(
						info.getNumerocomptecomplet(), principalAccount.getNumerocomptecomplet()));
				if (info.getSoldeDispo() == null) {
					info.setSoldeDispo(principalAccount.getSoldeDispo());
				}
				info.setCodeBanque(firstNonBlank(info.getCodeBanque(), principalAccount.getCodeBanque()));
				if (info.getNomClient() == null || info.getNomClient().isBlank()) {
					info.setNomClient(principalAccount.getNomDuCompte());
				}
			}
			info.setAccounts(accounts);
			info.setPeyapayMerchant(hasSupplierAccount || info.isPeyapayMerchant());
		}

		@SuppressWarnings("unchecked")
		Map<String, Object> wtypeClient = (Map<String, Object>) clientJson.get("wtypeClient");
		if (wtypeClient != null) {
			String estFournisseur = stringVal(wtypeClient.get("estFournisseur"), null);
			if (isYesFlag(estFournisseur)) {
				info.setPeyapayMerchant(true);
			}
		}

		// Root item field from /wClients/rechercheclient — do NOT infer from dateDeplafonner.
		if (clientJson.containsKey("deplafonner")) {
			info.setDeplafonne(parseBooleanFlag(clientJson.get("deplafonner")));
			info.setDeplafonnePresent(true);
		}

		splitNameIfNeeded(info);
		return info;
	}

	/**
	 * Peya {@code deplafonner} / similar flags: boolean, {@code O}/{@code N}, {@code true}/{@code false}, 1/0.
	 */
	private static boolean parseBooleanFlag(Object raw) {
		if (raw == null) {
			return false;
		}
		if (raw instanceof Boolean b) {
			return b;
		}
		if (raw instanceof Number n) {
			return n.intValue() != 0;
		}
		String v = raw.toString().trim();
		if (v.isEmpty()) {
			return false;
		}
		if ("false".equalsIgnoreCase(v) || "N".equalsIgnoreCase(v) || "0".equals(v) || "non".equalsIgnoreCase(v)) {
			return false;
		}
		return isYesFlag(v);
	}

	private PeyaAccountInfo mapAccount(Map<String, Object> compte) {
		PeyaAccountInfo account = new PeyaAccountInfo();
		account.setCodeClient(stringVal(compte.get("codeClient"), null));
		account.setNumerocomptecomplet(stringVal(compte.get("numerocomptecomplet"), null));
		account.setNomDuCompte(stringVal(compte.get("nomDuCompte"), null));
		account.setCodeBanque(stringVal(compte.get("codeBanque"), null));
		account.setCodeAgence(stringVal(compte.get("codeAgence"), null));
		account.setTypeCompte(firstNonBlank(
				stringVal(compte.get("typcpt"), null),
				stringVal(compte.get("typeCompte"), null)));
		account.setSoldeDispo(decimalVal(compte.get("soldedispo")));
		account.setSoldeCompta(decimalVal(compte.get("soldecompta")));
		account.setPrincipal("P".equalsIgnoreCase(account.getTypeCompte()));
		return account;
	}

	/** Peya flags: O / Y / true / 1 */
	private static boolean isYesFlag(String raw) {
		if (raw == null || raw.isBlank()) {
			return false;
		}
		String v = raw.trim();
		return "O".equalsIgnoreCase(v) || "Y".equalsIgnoreCase(v)
				|| "true".equalsIgnoreCase(v) || "1".equals(v);
	}

	private void applyClientFields(PeyaClientInfo info, Map<String, Object> src) {
		info.setCodeClient(firstNonBlank(info.getCodeClient(), stringVal(src.get("codeClient"), null)));
		info.setNomClient(firstNonBlank(info.getNomClient(),
				firstNonBlank(stringVal(src.get("nomClient"), null), stringVal(src.get("nomprenomsCltt"), null))));
		info.setFirstName(firstNonBlank(info.getFirstName(),
				firstNonBlank(stringVal(src.get("prenom"), null), stringVal(src.get("prenoms"), null))));
		info.setLastName(firstNonBlank(info.getLastName(), stringVal(src.get("nom"), null)));
		info.setGsmPrincipale(firstNonBlank(info.getGsmPrincipale(), stringVal(src.get("gsmPrincipale"), null)));
		info.setEmail(firstNonBlank(info.getEmail(), stringVal(src.get("email"), null)));
		info.setLogin(firstNonBlank(info.getLogin(),
				firstNonBlank(stringVal(src.get("login"), null), stringVal(src.get("loginClient"), null))));
		info.setCodeBanque(firstNonBlank(info.getCodeBanque(), stringVal(src.get("codeBanque"), null)));
		info.setAccountId(firstNonBlank(info.getAccountId(),
				firstNonBlank(stringVal(src.get("accountId"), null), stringVal(src.get("accoundId"), null))));
		info.setEtatClient(firstNonBlank(info.getEtatClient(), stringVal(src.get("etatClient"), null)));
		info.setCodePaysResidence(firstNonBlank(info.getCodePaysResidence(),
				stringVal(src.get("codePaysResidence"), null)));
		info.setIdNumber(firstNonBlank(info.getIdNumber(),
				firstNonBlank(stringVal(src.get("numPiece"), null),
						firstNonBlank(stringVal(src.get("NUM_PIECE"), null), stringVal(src.get("numPieceCltt"), null)))));
		info.setAdresse(firstNonBlank(info.getAdresse(),
				firstNonBlank(stringVal(src.get("adresse"), null), stringVal(src.get("Adresse"), null))));
		info.setProfession(firstNonBlank(info.getProfession(),
				firstNonBlank(stringVal(src.get("profession"), null), stringVal(src.get("PROFESSION"), null))));
		info.setLieuNaissance(firstNonBlank(info.getLieuNaissance(),
				firstNonBlank(stringVal(src.get("lieunaissance"), null),
						firstNonBlank(stringVal(src.get("lieuNaissance"), null), stringVal(src.get("lieunaissCltt"), null)))));
		if (info.getBirthDate() == null) {
			info.setBirthDate(parseDate(firstNonBlank(
					stringVal(src.get("datenaissance"), null),
					firstNonBlank(stringVal(src.get("dateNaissance"), null),
							firstNonBlank(stringVal(src.get("DAteNaissance"), null),
									stringVal(src.get("datenaissanceCltt"), null))))));
		}
	}

	private static void splitNameIfNeeded(PeyaClientInfo info) {
		if ((info.getFirstName() == null || info.getFirstName().isBlank())
				&& (info.getLastName() == null || info.getLastName().isBlank())
				&& info.getNomClient() != null && !info.getNomClient().isBlank()) {
			String[] parts = info.getNomClient().trim().split("\\s+");
			if (parts.length == 1) {
				info.setLastName(parts[0]);
			} else if (parts.length >= 2) {
				info.setLastName(parts[0]);
				info.setFirstName(String.join(" ", java.util.Arrays.copyOfRange(parts, 1, parts.length)));
			}
		}
	}

	private static java.time.LocalDate parseDate(String raw) {
		if (raw == null || raw.isBlank()) {
			return null;
		}
		String value = raw.trim();
		// Strip time if present: 1992-03-31T00:00:00 / 31/03/1992 00:00:00
		if (value.contains("T")) {
			value = value.substring(0, value.indexOf('T'));
		} else if (value.contains(" ") && value.matches(".*\\d{2}:\\d{2}.*")) {
			value = value.substring(0, value.indexOf(' '));
		}
		String[] patterns = { "yyyy-MM-dd", "dd/MM/yyyy", "dd-MM-yyyy", "yyyy/MM/dd" };
		for (String pattern : patterns) {
			try {
				return java.time.LocalDate.parse(value, java.time.format.DateTimeFormatter.ofPattern(pattern));
			} catch (Exception ignored) {
				// try next
			}
		}
		return null;
	}

	private String extractToken(String json, String fallback) throws IOException {
		Map<String, Object> envelope = objectMapper.readValue(json, new TypeReference<>() {
		});
		if (Boolean.TRUE.equals(envelope.get("hasError"))) {
			throw apiError(envelope, fallback);
		}
		@SuppressWarnings("unchecked")
		Map<String, Object> item = (Map<String, Object>) envelope.get("item");
		if (item == null || item.get("token") == null || item.get("token").toString().isBlank()) {
			throw new PeyaApiException(fallback + ": JWT token missing");
		}
		return item.get("token").toString();
	}

	private void assertNoError(String json, String fallback) throws IOException {
		assertNoError(json, fallback, false);
	}

	private void assertNoError(String json, String fallback, boolean allowEmptyBody) throws IOException {
		if (json == null || json.isBlank()) {
			if (allowEmptyBody) {
				return;
			}
			throw new PeyaApiException(fallback + ": empty response from Peya");
		}
		Map<String, Object> envelope = objectMapper.readValue(json, new TypeReference<>() {
		});
		if (Boolean.TRUE.equals(envelope.get("hasError"))) {
			throw apiError(envelope, fallback);
		}
	}

	private String encryptIfNeeded(String plain, String label) {
		if (!encryptPayloads) {
			return plain;
		}
		return peyaCryptoClient.encryptForApi(plain, label);
	}

	private String postJson(String url, Map<String, Object> body, String bearerToken, boolean noEncrypt)
			throws IOException {
		return postJson(url, body, bearerToken, noEncrypt, false);
	}

	private String postJson(String url, Map<String, Object> body, String bearerToken, boolean noEncrypt,
			boolean allowEmptyBody) throws IOException {
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
				throw new PeyaApiException("HTTP " + response.code() + " from " + url + ": "
						+ (responseBody.isBlank() ? "(empty body)" : responseBody));
			}
			if (responseBody.isBlank()) {
				if (allowEmptyBody) {
					log.debug("Peya empty body treated as success: HTTP {} {}", response.code(), url);
					return "";
				}
				log.warn("Peya empty body: HTTP {} {}", response.code(), url);
				throw new PeyaApiException("HTTP " + response.code() + " empty response from " + url);
			}
			return responseBody;
		}
	}

	private void ensureEnabled() {
		if (!enabled) {
			throw new PeyaApiException("Peya API is disabled (peya.api.enabled=false)");
		}
	}

	private String url(String path) {
		String base = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
		return path.startsWith("/") ? base + path : base + "/" + path;
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

	private static String firstNonBlank(String a, String b, String c) {
		return firstNonBlank(firstNonBlank(a, b), c);
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
