package com.monpeya.backend.api.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.monpeya.backend.api.contracts.FunctionalError;
import com.monpeya.backend.api.contracts.Request;
import com.monpeya.backend.api.contracts.Response;
import com.monpeya.backend.api.dto.ServiceProfileDto;
import com.monpeya.backend.api.dto.ServiceProfileRequestDto;
import com.monpeya.backend.api.entity.MpBusinessDocument;
import com.monpeya.backend.api.entity.MpModule;
import com.monpeya.backend.api.entity.MpServiceProfile;
import com.monpeya.backend.api.entity.MpSession;
import com.monpeya.backend.api.entity.MpUser;
import com.monpeya.backend.api.repository.MpBusinessDocumentRepository;
import com.monpeya.backend.api.repository.MpModuleRepository;
import com.monpeya.backend.api.repository.MpServiceProfileRepository;
import com.monpeya.backend.api.repository.MpSessionRepository;

/**
 * Per-service CLIENT vs BUSINESS profile. Leadway stays CLIENT_ONLY.
 */
@Service
public class ServiceProfileBusiness {

	public static final String ROLE_CLIENT = "CLIENT";
	public static final String ROLE_BUSINESS = "BUSINESS";
	public static final String MODEL_CLIENT_ONLY = "CLIENT_ONLY";
	public static final String MODEL_DUAL = "CLIENT_AND_BUSINESS";
	public static final String PATH_DOCUMENTS = "DOCUMENTS";
	public static final String PATH_MERCHANT = "PEYAPAY_MERCHANT";

	private static final Set<String> DOC_TYPES = Set.of(
			"ID_CARD_FRONT", "ID_CARD_BACK", "BUSINESS_REG", "OTHER");

	@Autowired
	private MpModuleRepository moduleRepository;

	@Autowired
	private MpServiceProfileRepository profileRepository;

	@Autowired
	private MpBusinessDocumentRepository documentRepository;

	@Autowired
	private MpSessionRepository sessionRepository;

	@Autowired
	private FunctionalError functionalError;

	@Transactional
	public Response<ServiceProfileDto> listMine(Request<ServiceProfileRequestDto> request, Locale locale) {
		Response<ServiceProfileDto> response = new Response<>();
		MpUser user = requireUser(request, response, locale);
		if (user == null) {
			return response;
		}
		ensureProfiles(user);
		boolean merchant = Boolean.TRUE.equals(user.getIsPeyapayMerchant());
		List<ServiceProfileDto> items = profileRepository.findByUser_IdOrderByModule_SortOrderAsc(user.getId())
				.stream()
				.map(p -> {
					p.setIsPeyapayMerchant(merchant);
					return toDto(p, user);
				})
				.toList();
		response.setItems(items);
		response.setCount((long) items.size());
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional
	public Response<ServiceProfileDto> getOne(Request<ServiceProfileRequestDto> request, Locale locale) {
		Response<ServiceProfileDto> response = new Response<>();
		MpUser user = requireUser(request, response, locale);
		if (user == null) {
			return response;
		}
		String moduleCode = moduleCode(request);
		if (moduleCode == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("moduleCode", locale));
			return response;
		}
		MpModule module = moduleRepository.findByCodeAndIsActiveTrue(moduleCode).orElse(null);
		if (module == null) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_EXIST("module", locale));
			return response;
		}
		MpServiceProfile profile = getOrCreate(user, module);
		profile.setIsPeyapayMerchant(Boolean.TRUE.equals(user.getIsPeyapayMerchant()));
		response.setItem(toDto(profile, user));
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	/**
	 * Start business upgrade: DOCUMENTS (settings ID upload) or PEYAPAY_MERCHANT shortcut.
	 * Merchant path is mock-approved so they can subscribe as BUSINESS next.
	 */
	@Transactional
	public Response<ServiceProfileDto> startBusinessUpgrade(Request<ServiceProfileRequestDto> request,
			Locale locale) {
		Response<ServiceProfileDto> response = new Response<>();
		MpUser user = requireUser(request, response, locale);
		if (user == null) {
			return response;
		}
		String moduleCode = moduleCode(request);
		if (moduleCode == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("moduleCode", locale));
			return response;
		}
		MpModule module = moduleRepository.findByCodeAndIsActiveTrue(moduleCode).orElse(null);
		if (module == null) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_EXIST("module", locale));
			return response;
		}
		if (MODEL_CLIENT_ONLY.equals(module.getRoleModel())) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL(
					"this service is client-only (no business role)", locale));
			return response;
		}

		ServiceProfileRequestDto data = request.getData();
		String path = data != null && data.getUpgradePath() != null
				? data.getUpgradePath().trim().toUpperCase()
				: PATH_DOCUMENTS;
		if (!PATH_DOCUMENTS.equals(path) && !PATH_MERCHANT.equals(path)) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("upgradePath", locale));
			return response;
		}

		MpServiceProfile profile = getOrCreate(user, module);
		if ("APPROVED".equals(profile.getBusinessStatus())
				&& ROLE_BUSINESS.equals(profile.getCurrentRole())) {
			response.setItem(toDto(profile, user));
			response.setHasError(false);
			response.setStatus(functionalError.SUCCESS("already business", locale));
			return response;
		}

		profile.setUpgradePath(path);
		// Merchant = Peya rechercheclient has typcpt=S (cached on MP_USER at login).
		boolean merchant = Boolean.TRUE.equals(user.getIsPeyapayMerchant());
		profile.setIsPeyapayMerchant(merchant);
		if (PATH_MERCHANT.equals(path)) {
			if (!merchant) {
				response.setHasError(true);
				response.setStatus(functionalError.AUTH_FAIL(
						"not a PeyaPay supplier (no typcpt=S account)", locale));
				return response;
			}
			// PeyaPay merchant shortcut: ready to subscribe as BUSINESS.
			profile.setBusinessStatus("APPROVED");
			profile.setCurrentRole(ROLE_BUSINESS);
			profile.setNote("Approved via PeyaPay supplier account (typcpt=S)");
		} else {
			profile.setBusinessStatus("PENDING_DOCS");
			profile.setCurrentRole(ROLE_CLIENT);
			profile.setNote("Upload ID / business documents in settings");
		}
		profile.setUpdatedAt(LocalDateTime.now());
		profile = profileRepository.save(profile);

		response.setItem(toDto(profile, user));
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS(
				PATH_MERCHANT.equals(path) ? "merchant path — subscribe as BUSINESS" : "awaiting documents",
				locale));
		return response;
	}

	@Transactional
	public Response<ServiceProfileDto> addDocument(Request<ServiceProfileRequestDto> request, Locale locale) {
		Response<ServiceProfileDto> response = new Response<>();
		MpUser user = requireUser(request, response, locale);
		if (user == null) {
			return response;
		}
		String moduleCode = moduleCode(request);
		ServiceProfileRequestDto data = request != null ? request.getData() : null;
		if (moduleCode == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("moduleCode", locale));
			return response;
		}
		String docType = data != null && data.getDocType() != null
				? data.getDocType().trim().toUpperCase()
				: null;
		if (docType == null || !DOC_TYPES.contains(docType)) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("docType", locale));
			return response;
		}
		MpModule module = moduleRepository.findByCodeAndIsActiveTrue(moduleCode).orElse(null);
		if (module == null || MODEL_CLIENT_ONLY.equals(module.getRoleModel())) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_EXIST("module", locale));
			return response;
		}

		MpServiceProfile profile = getOrCreate(user, module);
		if (MODEL_CLIENT_ONLY.equals(module.getRoleModel())) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL("client-only service", locale));
			return response;
		}

		MpBusinessDocument doc = new MpBusinessDocument();
		doc.setProfile(profile);
		doc.setDocType(docType);
		doc.setFileRef(data.getFileRef());
		doc.setStatus("PENDING");
		doc.setCreatedAt(LocalDateTime.now());
		doc.setUpdatedAt(LocalDateTime.now());
		documentRepository.save(doc);

		profile.setUpgradePath(PATH_DOCUMENTS);
		profile.setBusinessStatus("PENDING_REVIEW");
		profile.setUpdatedAt(LocalDateTime.now());
		// Shell: auto-accept after first ID doc so mobile flow can continue (mock review).
		if ("ID_CARD_FRONT".equals(docType) || "ID_CARD_BACK".equals(docType)) {
			doc.setStatus("ACCEPTED");
			documentRepository.save(doc);
			profile.setBusinessStatus("APPROVED");
			profile.setCurrentRole(ROLE_BUSINESS);
			profile.setNote("Documents accepted (mock review)");
		}
		profile = profileRepository.save(profile);

		response.setItem(toDto(profile, user));
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	private void ensureProfiles(MpUser user) {
		for (MpModule module : moduleRepository.findByIsActiveTrueOrderBySortOrderAsc()) {
			getOrCreate(user, module);
		}
	}

	private MpServiceProfile getOrCreate(MpUser user, MpModule module) {
		return profileRepository.findByUser_IdAndModule_Code(user.getId(), module.getCode())
				.orElseGet(() -> {
					MpServiceProfile p = new MpServiceProfile();
					p.setUser(user);
					p.setModule(module);
					p.setCurrentRole(ROLE_CLIENT);
					p.setBusinessStatus("NONE");
					p.setIsPeyapayMerchant(false);
					p.setCreatedAt(LocalDateTime.now());
					p.setUpdatedAt(LocalDateTime.now());
					return profileRepository.save(p);
				});
	}

	private ServiceProfileDto toDto(MpServiceProfile profile, MpUser user) {
		MpModule module = profile.getModule();
		boolean dual = MODEL_DUAL.equals(module.getRoleModel());
		boolean approved = "APPROVED".equals(profile.getBusinessStatus());

		ServiceProfileDto dto = new ServiceProfileDto();
		dto.setModuleCode(module.getCode());
		dto.setModuleName(module.getName());
		dto.setRoleModel(module.getRoleModel());
		dto.setCurrentRole(profile.getCurrentRole());
		dto.setBusinessStatus(profile.getBusinessStatus());
		dto.setUpgradePath(profile.getUpgradePath());
		boolean merchant = Boolean.TRUE.equals(user.getIsPeyapayMerchant());
		dto.setIsPeyapayMerchant(merchant);
		dto.setCanUpgradeToBusiness(dual && !approved);
		boolean deplafonne = Boolean.TRUE.equals(user.getIsDeplafonne());
		dto.setIsDeplafonne(deplafonne);
		dto.setNeedsDeplafonnementRequest(!deplafonne);
		// Dual-role: CLIENT straight debit only if déplafonné; BUSINESS via paid request after identity.
		dto.setCanSubscribeAsClient(dual && deplafonne);
		dto.setCanSubscribeAsBusiness(dual && approved);
		dto.setDocuments(documentRepository.findByProfile_IdOrderByCreatedAtDesc(profile.getId()).stream()
				.map(d -> {
					ServiceProfileDto.BusinessDocumentDto bd = new ServiceProfileDto.BusinessDocumentDto();
					bd.setDocumentId(d.getId());
					bd.setDocType(d.getDocType());
					bd.setFileRef(d.getFileRef());
					bd.setStatus(d.getStatus());
					return bd;
				})
				.toList());
		return dto;
	}

	private MpUser requireUser(Request<ServiceProfileRequestDto> request, Response<?> response, Locale locale) {
		ServiceProfileRequestDto data = request != null ? request.getData() : null;
		String token = data != null ? data.getAccessToken() : null;
		if (token == null || token.isBlank()) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("accessToken", locale));
			return null;
		}
		MpSession session = sessionRepository.findByAccessTokenAndRevokedFalse(token.trim()).orElse(null);
		if (session == null || session.getExpiresAt().isBefore(LocalDateTime.now())) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL("session expired", locale));
			return null;
		}
		return session.getUser();
	}

	private static String moduleCode(Request<ServiceProfileRequestDto> request) {
		ServiceProfileRequestDto data = request != null ? request.getData() : null;
		if (data == null || data.getModuleCode() == null || data.getModuleCode().isBlank()) {
			return null;
		}
		return data.getModuleCode().trim();
	}
}
