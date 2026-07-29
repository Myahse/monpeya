package com.monpeya.backend.api.service;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.monpeya.backend.api.contracts.FunctionalError;
import com.monpeya.backend.api.contracts.Request;
import com.monpeya.backend.api.contracts.Response;
import com.monpeya.backend.api.dto.AuthPhoneDto;
import com.monpeya.backend.api.dto.AuthSessionDto;
import com.monpeya.backend.api.dto.AuthUserDto;
import com.monpeya.backend.api.entity.MpAccount;
import com.monpeya.backend.api.entity.MpDevice;
import com.monpeya.backend.api.entity.MpOtpChallenge;
import com.monpeya.backend.api.entity.MpSession;
import com.monpeya.backend.api.entity.MpUser;
import com.monpeya.backend.api.integration.peya.PeyaAccountInfo;
import com.monpeya.backend.api.integration.peya.PeyaApiClient;
import com.monpeya.backend.api.integration.peya.PeyaApiException;
import com.monpeya.backend.api.integration.peya.PeyaClientInfo;
import com.monpeya.backend.api.repository.MpAccountRepository;
import com.monpeya.backend.api.repository.MpDeviceRepository;
import com.monpeya.backend.api.repository.MpOtpChallengeRepository;
import com.monpeya.backend.api.repository.MpSessionRepository;
import com.monpeya.backend.api.repository.MpUserRepository;


@Service
public class AuthBusiness {

	@Autowired
	private PeyaApiClient peyaApiClient;

	@Autowired
	private MpUserRepository userRepository;

	@Autowired
	private MpAccountRepository accountRepository;

	@Autowired
	private MpDeviceRepository deviceRepository;

	@Autowired
	private MpSessionRepository sessionRepository;

	@Autowired
	private MpOtpChallengeRepository otpRepository;

	@Autowired
	private FunctionalError functionalError;

	@Value("${auth.access-token-hours:12}")
	private long accessTokenHours;

	@Value("${auth.refresh-token-days:30}")
	private long refreshTokenDays;

	@Transactional
	public Response<AuthSessionDto> lookup(Request<AuthPhoneDto> request, Locale locale) {
		Response<AuthSessionDto> response = new Response<>();
		AuthPhoneDto data = request != null ? request.getData() : null;
		String phone = normalizePhone(data != null ? data.getPhone() : null);
		if (phone == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("phone", locale));
			return response;
		}

		try {
			List<PeyaClientInfo> clients = peyaApiClient.searchGsm(phone);
			boolean known = !clients.isEmpty();
			PeyaClientInfo fromGsm = known ? clients.get(0) : null;
			PeyaClientInfo fromDetail = enrichFromRechercheClient(fromGsm);
			PeyaClientInfo peya = mergeClientInfo(fromGsm, fromDetail, null, phone);

			MpUser user = upsertFromPeya(phone, peya, known);

			AuthSessionDto dto = new AuthSessionDto();
			dto.setKnownPeyaClient(known);
			dto.setOtpRequired(!known);
			dto.setUser(toUserDto(user));
			response.setItem(dto);
			response.setHasError(false);
			response.setStatus(functionalError.SUCCESS("", locale));
			return response;
		} catch (PeyaApiException ex) {
			return peyaFailure(response, ex, locale);
		}
	}

	@Transactional
	public Response<AuthSessionDto> sendOtp(Request<AuthPhoneDto> request, Locale locale) {
		Response<AuthSessionDto> response = new Response<>();
		AuthPhoneDto data = request != null ? request.getData() : null;
		String phone = normalizePhone(data != null ? data.getPhone() : null);
		if (phone == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("phone", locale));
			return response;
		}

		try {
			peyaApiClient.sendOtp(
					phone,
					data.getResidenceCountry(),
					data.getImei(),
					data.getModele(),
					data.getPlatform());

			MpOtpChallenge challenge = new MpOtpChallenge();
			challenge.setPhone(phone);
			challenge.setPurpose("REGISTER");
			challenge.setStatus("SENT");
			otpRepository.save(challenge);

			AuthSessionDto dto = new AuthSessionDto();
			dto.setOtpRequired(true);
			dto.setKnownPeyaClient(false);
			response.setItem(dto);
			response.setHasError(false);
			response.setStatus(functionalError.SUCCESS("OTP sent", locale));
			return response;
		} catch (PeyaApiException ex) {
			MpOtpChallenge failed = new MpOtpChallenge();
			failed.setPhone(phone);
			failed.setPurpose("REGISTER");
			failed.setStatus("FAILED");
			otpRepository.save(failed);
			return peyaFailure(response, ex, locale);
		}
	}

	@Transactional
	public Response<AuthSessionDto> verifyOtp(Request<AuthPhoneDto> request, Locale locale) {
		Response<AuthSessionDto> response = new Response<>();
		AuthPhoneDto data = request != null ? request.getData() : null;
		String phone = normalizePhone(data != null ? data.getPhone() : null);
		String code = data != null ? trim(data.getOtpCode()) : null;
		if (phone == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("phone", locale));
			return response;
		}
		if (code == null || code.length() < 4) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("otpCode", locale));
			return response;
		}

		try {
			peyaApiClient.verifyOtp(phone, code);

			MpOtpChallenge challenge = new MpOtpChallenge();
			challenge.setPhone(phone);
			challenge.setPurpose("REGISTER");
			challenge.setStatus("VERIFIED");
			challenge.setVerifiedAt(LocalDateTime.now());
			otpRepository.save(challenge);

			MpUser user = userRepository.findByPhone(phone).orElseGet(() -> {
				MpUser created = new MpUser();
				created.setPhone(phone);
				created.setIsPeyaClient(false);
				created.setStatus("PENDING");
				created.setPeyaStatus("NEW_CUSTOMER");
				return userRepository.save(created);
			});

			AuthSessionDto dto = new AuthSessionDto();
			dto.setOtpRequired(false);
			dto.setKnownPeyaClient(Boolean.TRUE.equals(user.getIsPeyaClient()));
			dto.setUser(toUserDto(user));
			response.setItem(dto);
			response.setHasError(false);
			response.setStatus(functionalError.SUCCESS("OTP verified", locale));
			return response;
		} catch (PeyaApiException ex) {
			return peyaFailure(response, ex, locale);
		}
	}

	@Transactional
	public Response<AuthSessionDto> login(Request<AuthPhoneDto> request, Locale locale) {
		Response<AuthSessionDto> response = new Response<>();
		AuthPhoneDto data = request != null ? request.getData() : null;
		String phone = normalizePhone(data != null ? data.getPhone() : null);
		String pin = data != null ? trim(data.getPin()) : null;
		if (phone == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("phone", locale));
			return response;
		}
		if (pin == null || pin.length() < 4) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("pin", locale));
			return response;
		}

		try {
			peyaApiClient.verifyPin(phone, pin);
			// Same as Flutter: client JWT, or admin bearer when /authclient/token returns 919.
			String peyaToken = peyaApiClient.loginClientTokenOrAdminFallback(
					phone, pin, data.getResidenceCountry());

			List<PeyaClientInfo> clients = peyaApiClient.searchGsm(phone);
			PeyaClientInfo fromGsm = clients.isEmpty() ? null : clients.get(0);
			PeyaClientInfo fromDetail = enrichFromRechercheClient(fromGsm);
			PeyaClientInfo fromState = null;
			try {
				fromState = peyaApiClient.fetchClientState(
						phone,
						data.getResidenceCountry(),
						data.getImei(),
						data.getModele(),
						data.getPlatform());
			} catch (PeyaApiException ex) {
				// Profile enrich is best-effort; PIN already verified.
			}
			// Prefer full profile from rechercheclient for name / birth date / ID.
			if (fromDetail == null && fromState != null) {
				fromDetail = enrichFromRechercheClient(fromState);
			}
			PeyaClientInfo peya = mergeClientInfo(fromGsm, fromDetail, fromState, phone);
			MpUser user = upsertFromPeya(phone, peya, true);
			user.setLastLoginAt(LocalDateTime.now());
			user.setUpdatedAt(LocalDateTime.now());
			user = userRepository.save(user);

			MpDevice device = upsertDevice(user, data);
			MpSession session = createSession(user, device, peyaToken);

			AuthSessionDto dto = toSessionDto(session, user);
			dto.setKnownPeyaClient(true);
			dto.setOtpRequired(false);
			response.setItem(dto);
			response.setHasError(false);
			response.setStatus(functionalError.SUCCESS("", locale));
			return response;
		} catch (PeyaApiException ex) {
			return peyaFailure(response, ex, locale);
		}
	}

	@Transactional
	public Response<AuthSessionDto> refresh(Request<AuthPhoneDto> request, Locale locale) {
		Response<AuthSessionDto> response = new Response<>();
		AuthPhoneDto data = request != null ? request.getData() : null;
		String refreshToken = data != null ? trim(data.getRefreshToken()) : null;
		if (refreshToken == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("refreshToken", locale));
			return response;
		}

		MpSession existing = sessionRepository.findByRefreshTokenAndRevokedFalse(refreshToken).orElse(null);
		if (existing == null || existing.getRefreshExpiresAt().isBefore(LocalDateTime.now())) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL("session expired", locale));
			return response;
		}

		existing.setRevoked(true);
		sessionRepository.save(existing);

		MpUser user = existing.getUser();
		MpSession session = createSession(user, existing.getDevice(), existing.getPeyaAccessToken());
		response.setItem(toSessionDto(session, user));
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional
	public Response<AuthSessionDto> logout(Request<AuthPhoneDto> request, Locale locale) {
		Response<AuthSessionDto> response = new Response<>();
		AuthPhoneDto data = request != null ? request.getData() : null;
		String accessToken = data != null ? trim(data.getAccessToken()) : null;
		if (accessToken == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("accessToken", locale));
			return response;
		}

		sessionRepository.findByAccessTokenAndRevokedFalse(accessToken).ifPresent(session -> {
			session.setRevoked(true);
			sessionRepository.save(session);
		});

		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("logged out", locale));
		return response;
	}

	@Transactional(readOnly = true)
	public Response<AuthUserDto> me(Request<AuthPhoneDto> request, Locale locale) {
		Response<AuthUserDto> response = new Response<>();
		AuthPhoneDto data = request != null ? request.getData() : null;
		String accessToken = data != null ? trim(data.getAccessToken()) : null;
		if (accessToken == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("accessToken", locale));
			return response;
		}

		MpSession session = sessionRepository.findByAccessTokenAndRevokedFalse(accessToken).orElse(null);
		if (session == null || session.getExpiresAt().isBefore(LocalDateTime.now())) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL("session expired", locale));
			return response;
		}

		response.setItem(toUserDto(session.getUser()));
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	/**
	 * Re-fetch Peya wclients profile for a known phone and upsert {@code MP_USER} + {@code MP_ACCOUNT}.
	 */
	@Transactional
	public MpUser syncProfileFromPeya(String phone, String residenceCountry, String imei, String modele,
			String platform) {
		String normalized = normalizePhone(phone);
		if (normalized == null) {
			throw new PeyaApiException("phone is empty");
		}
		List<PeyaClientInfo> clients = peyaApiClient.searchGsm(normalized);
		PeyaClientInfo fromGsm = clients.isEmpty() ? null : clients.get(0);
		PeyaClientInfo fromDetail = enrichFromRechercheClient(fromGsm);
		PeyaClientInfo fromState = null;
		try {
			fromState = peyaApiClient.fetchClientState(normalized, residenceCountry, imei, modele, platform);
		} catch (PeyaApiException ignored) {
			// best-effort
		}
		if (fromDetail == null && fromState != null) {
			fromDetail = enrichFromRechercheClient(fromState);
		}
		PeyaClientInfo merged = mergeClientInfo(fromGsm, fromDetail, fromState, normalized);
		return upsertFromPeya(normalized, merged, true);
	}

	public AuthUserDto toUserDtoPublic(MpUser user) {
		return toUserDto(user);
	}

	/** Best-effort full KYC profile via {@code /wClients/rechercheclient}. */
	private PeyaClientInfo enrichFromRechercheClient(PeyaClientInfo seed) {
		if (seed == null || seed.getCodeClient() == null || seed.getCodeClient().isBlank()) {
			return null;
		}
		try {
			return peyaApiClient.searchClientByCode(seed.getCodeClient());
		} catch (PeyaApiException ex) {
			return null;
		}
	}

	private MpUser upsertFromPeya(String phone, PeyaClientInfo peya, boolean known) {
		MpUser user = userRepository.findByPhone(phone).orElseGet(MpUser::new);
		boolean isNew = user.getId() == null;
		user.setPhone(phone);
		user.setIsPeyaClient(known);
		if (peya != null) {
			setIfPresent(peya.getCodeClient(), user::setCodeClient);
			if (peya.getNomClient() != null && !peya.getNomClient().isBlank()) {
				user.setNomClient(peya.getNomClient());
				user.setDisplayName(peya.getNomClient());
			}
			setIfPresent(peya.getEmail(), user::setEmail);
			setIfPresent(peya.getAccountId(), user::setAccountId);
			setIfPresent(peya.getFirstName(), user::setFirstName);
			setIfPresent(peya.getLastName(), user::setLastName);
			if (peya.getBirthDate() != null) {
				user.setBirthDate(peya.getBirthDate());
			}
			setIfPresent(peya.getIdNumber(), user::setIdNumber);
			setIfPresent(peya.getAdresse(), user::setAdresse);
			setIfPresent(peya.getProfession(), user::setProfession);
			setIfPresent(peya.getLieuNaissance(), user::setLieuNaissance);
			setIfPresent(peya.getCodePaysResidence(), user::setCodePaysResidence);
			setIfPresent(peya.getLogin(), user::setLoginClient);
			setIfPresent(peya.getCodeBanque(), user::setCodeBanque);
			setIfPresent(peya.getNumerocomptecomplet(), user::setNumerocomptecomplet);
			if (peya.getSoldeDispo() != null) {
				user.setSoldeDispo(peya.getSoldeDispo());
			}
			if (peya.getEtatClient() != null && !peya.getEtatClient().isBlank()) {
				user.setPeyaStatus(peya.getEtatClient());
			} else if (known) {
				user.setPeyaStatus("CUSTOMER");
			}
			user.setStatus("ACTIVE");
		} else if (isNew) {
			user.setPeyaStatus("UNKNOWN");
			user.setStatus("PENDING");
		}
		if (peya != null) {
			boolean merchant = peya.isPeyapayMerchant()
					|| (peya.getAccounts() != null && peya.getAccounts().stream()
							.anyMatch(a -> a.getTypeCompte() != null
									&& "S".equalsIgnoreCase(a.getTypeCompte().trim())));
			user.setIsPeyapayMerchant(merchant);
			user.setIsDeplafonne(peya.isDeplafonne());
		}
		user.setUpdatedAt(LocalDateTime.now());
		if (isNew) {
			user.setCreatedAt(LocalDateTime.now());
		}
		user = userRepository.save(user);
		if (peya != null && peya.getAccounts() != null && !peya.getAccounts().isEmpty()) {
			replaceAccounts(user, peya.getAccounts());
		}
		return user;
	}

	private void replaceAccounts(MpUser user, List<PeyaAccountInfo> accounts) {
		accountRepository.deleteByUserId(user.getId());
		accountRepository.flush();
		LocalDateTime now = LocalDateTime.now();
		for (PeyaAccountInfo src : accounts) {
			MpAccount account = new MpAccount();
			account.setUser(user);
			account.setCodeClient(firstNonBlank(src.getCodeClient(), user.getCodeClient()));
			account.setNumerocomptecomplet(src.getNumerocomptecomplet());
			account.setNomDuCompte(src.getNomDuCompte());
			account.setCodeBanque(src.getCodeBanque());
			account.setCodeAgence(src.getCodeAgence());
			account.setTypeCompte(src.getTypeCompte());
			account.setSoldeDispo(src.getSoldeDispo());
			account.setSoldeCompta(src.getSoldeCompta());
			account.setIsPrincipal(src.isPrincipal());
			account.setCreatedAt(now);
			account.setUpdatedAt(now);
			accountRepository.save(account);
		}
	}

	private static String firstNonBlank(String a, String b) {
		if (a != null && !a.isBlank()) {
			return a;
		}
		return b;
	}

	/**
	 * Merge GSM lookup + full client search + etatclient.
	 * Detail (rechercheclient) wins for KYC fields when present.
	 */
	private static PeyaClientInfo mergeClientInfo(
			PeyaClientInfo gsm, PeyaClientInfo detail, PeyaClientInfo state, String phone) {
		PeyaClientInfo merged = new PeyaClientInfo();
		merged.setGsmPrincipale(phone);
		copyProfile(merged, gsm);
		copyProfile(merged, state);
		// Full client search wins for name / birth date / ID / address.
		copyProfile(merged, detail);
		// rechercheclient root "deplafonner" is authoritative when present (true or false).
		if (detail != null && detail.isDeplafonnePresent()) {
			merged.setDeplafonne(detail.isDeplafonne());
			merged.setDeplafonnePresent(true);
		}
		return merged;
	}

	private static void copyProfile(PeyaClientInfo target, PeyaClientInfo source) {
		if (source == null) {
			return;
		}
		if (notBlank(source.getCodeClient())) {
			target.setCodeClient(source.getCodeClient());
		}
		if (notBlank(source.getNomClient())) {
			target.setNomClient(source.getNomClient());
		}
		if (notBlank(source.getFirstName())) {
			target.setFirstName(source.getFirstName());
		}
		if (notBlank(source.getLastName())) {
			target.setLastName(source.getLastName());
		}
		if (notBlank(source.getGsmPrincipale())) {
			target.setGsmPrincipale(source.getGsmPrincipale());
		}
		if (notBlank(source.getEmail())) {
			target.setEmail(source.getEmail());
		}
		if (notBlank(source.getLogin())) {
			target.setLogin(source.getLogin());
		}
		if (notBlank(source.getCodeBanque())) {
			target.setCodeBanque(source.getCodeBanque());
		}
		if (notBlank(source.getAccountId())) {
			target.setAccountId(source.getAccountId());
		}
		if (notBlank(source.getNumerocomptecomplet())) {
			target.setNumerocomptecomplet(source.getNumerocomptecomplet());
		}
		if (source.getSoldeDispo() != null) {
			target.setSoldeDispo(source.getSoldeDispo());
		}
		if (notBlank(source.getEtatClient())) {
			target.setEtatClient(source.getEtatClient());
		}
		if (notBlank(source.getCodePaysResidence())) {
			target.setCodePaysResidence(source.getCodePaysResidence());
		}
		if (source.getBirthDate() != null) {
			target.setBirthDate(source.getBirthDate());
		}
		if (notBlank(source.getIdNumber())) {
			target.setIdNumber(source.getIdNumber());
		}
		if (notBlank(source.getAdresse())) {
			target.setAdresse(source.getAdresse());
		}
		if (notBlank(source.getProfession())) {
			target.setProfession(source.getProfession());
		}
		if (notBlank(source.getLieuNaissance())) {
			target.setLieuNaissance(source.getLieuNaissance());
		}
		if (source.getAccounts() != null && !source.getAccounts().isEmpty()) {
			target.setAccounts(source.getAccounts());
		}
		if (source.isPeyapayMerchant()) {
			target.setPeyapayMerchant(true);
		}
		if (source.isDeplafonnePresent()) {
			target.setDeplafonne(source.isDeplafonne());
			target.setDeplafonnePresent(true);
		} else if (source.isDeplafonne()) {
			target.setDeplafonne(true);
		}
	}

	private static void setIfPresent(String value, java.util.function.Consumer<String> setter) {
		if (notBlank(value)) {
			setter.accept(value);
		}
	}

	private static boolean notBlank(String value) {
		return value != null && !value.isBlank();
	}

	private MpDevice upsertDevice(MpUser user, AuthPhoneDto data) {
		String imei = data != null ? trim(data.getImei()) : null;
		if (imei == null) {
			return null;
		}
		MpDevice device = deviceRepository.findFirstByUser_IdAndImei(user.getId(), imei).orElseGet(MpDevice::new);
		device.setUser(user);
		device.setImei(imei);
		device.setModele(data.getModele());
		device.setPlatform(data.getPlatform());
		device.setLastSeenAt(LocalDateTime.now());
		if (device.getId() == null) {
			device.setCreatedAt(LocalDateTime.now());
		}
		return deviceRepository.save(device);
	}

	private MpSession createSession(MpUser user, MpDevice device, String peyaToken) {
		LocalDateTime now = LocalDateTime.now();
		MpSession session = new MpSession();
		session.setUser(user);
		session.setDevice(device);
		session.setAccessToken(UUID.randomUUID().toString().replace("-", ""));
		session.setRefreshToken(UUID.randomUUID().toString().replace("-", ""));
		session.setPeyaAccessToken(peyaToken);
		session.setExpiresAt(now.plus(accessTokenHours, ChronoUnit.HOURS));
		session.setRefreshExpiresAt(now.plus(refreshTokenDays, ChronoUnit.DAYS));
		session.setRevoked(false);
		session.setCreatedAt(now);
		return sessionRepository.save(session);
	}

	private AuthSessionDto toSessionDto(MpSession session, MpUser user) {
		AuthSessionDto dto = new AuthSessionDto();
		dto.setAccessToken(session.getAccessToken());
		dto.setRefreshToken(session.getRefreshToken());
		dto.setExpiresAt(session.getExpiresAt());
		dto.setRefreshExpiresAt(session.getRefreshExpiresAt());
		dto.setUser(toUserDto(user));
		return dto;
	}

	private AuthUserDto toUserDto(MpUser user) {
		AuthUserDto dto = new AuthUserDto();
		dto.setUserId(user.getId());
		dto.setPhone(user.getPhone());
		dto.setCodeClient(user.getCodeClient());
		dto.setNomClient(user.getNomClient());
		dto.setEmail(user.getEmail());
		dto.setAccountId(user.getAccountId());
		dto.setPeyaStatus(user.getPeyaStatus());
		dto.setIsPeyaClient(user.getIsPeyaClient());
		dto.setIsPeyapayMerchant(Boolean.TRUE.equals(user.getIsPeyapayMerchant()));
		dto.setIsDeplafonne(Boolean.TRUE.equals(user.getIsDeplafonne()));
		dto.setStatus(user.getStatus());
		dto.setDisplayName(user.getDisplayName() != null ? user.getDisplayName() : user.getNomClient());
		dto.setFirstName(user.getFirstName());
		dto.setLastName(user.getLastName());
		dto.setBirthDate(user.getBirthDate());
		dto.setIdNumber(user.getIdNumber());
		dto.setAdresse(user.getAdresse());
		dto.setProfession(user.getProfession());
		dto.setLieuNaissance(user.getLieuNaissance());
		dto.setCodePaysResidence(user.getCodePaysResidence());
		dto.setLoginClient(user.getLoginClient());
		dto.setCodeBanque(user.getCodeBanque());
		dto.setNumerocomptecomplet(user.getNumerocomptecomplet());
		dto.setSoldeDispo(user.getSoldeDispo());
		dto.setKycStatus(user.getKycStatus());
		return dto;
	}

	private Response<AuthSessionDto> peyaFailure(Response<AuthSessionDto> response, PeyaApiException ex, Locale locale) {
		response.setHasError(true);
		response.setStatus(functionalError.DISALLOWED_OPERATION(ex.getMessage(), locale));
		return response;
	}

	/** Keep local GSM digits — strip CI country code so Peya rechercheGsm matches. */
	private static String normalizePhone(String phone) {
		if (phone == null || phone.isBlank()) {
			return null;
		}
		String digits = phone.replaceAll("\\D", "");
		if (digits.startsWith("00225") && digits.length() > 10) {
			digits = digits.substring(5);
		} else if (digits.startsWith("225") && digits.length() > 10) {
			digits = digits.substring(3);
		}
		return digits.isEmpty() ? null : digits;
	}

	private static String trim(String value) {
		if (value == null) {
			return null;
		}
		String t = value.trim();
		return t.isEmpty() ? null : t;
	}
}
