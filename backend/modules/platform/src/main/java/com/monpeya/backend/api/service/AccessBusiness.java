package com.monpeya.backend.api.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.monpeya.backend.api.contracts.FunctionalError;
import com.monpeya.backend.api.contracts.Request;
import com.monpeya.backend.api.contracts.Response;
import com.monpeya.backend.api.dto.AccessCheckDto;
import com.monpeya.backend.api.dto.AccessDecisionDto;
import com.monpeya.backend.api.dto.ModuleCatalogDto;
import com.monpeya.backend.api.entity.MpAccessLog;
import com.monpeya.backend.api.entity.MpModule;
import com.monpeya.backend.api.entity.MpServiceAction;
import com.monpeya.backend.api.entity.MpSession;
import com.monpeya.backend.api.entity.MpSubscription;
import com.monpeya.backend.api.entity.MpUser;
import com.monpeya.backend.api.entity.MpUserEntitlement;
import com.monpeya.backend.api.entity.MpServiceProfile;
import com.monpeya.backend.api.repository.MpAccessLogRepository;
import com.monpeya.backend.api.repository.MpModuleParamRepository;
import com.monpeya.backend.api.repository.MpModuleRepository;
import com.monpeya.backend.api.repository.MpServiceActionRepository;
import com.monpeya.backend.api.repository.MpServiceProfileRepository;
import com.monpeya.backend.api.repository.MpSessionRepository;
import com.monpeya.backend.api.repository.MpSubscriptionRepository;
import com.monpeya.backend.api.repository.MpUserEntitlementRepository;

/**
 * Guest-open vs auth-gated vs subscription-gated access for the super-app.
 */
@Service
public class AccessBusiness {

	public static final String LEVEL_GUEST = "GUEST";
	public static final String LEVEL_AUTH = "AUTH";
	public static final String LEVEL_SUBSCRIPTION = "SUBSCRIPTION";

	@Autowired
	private MpModuleRepository moduleRepository;

	@Autowired
	private MpModuleParamRepository moduleParamRepository;

	@Autowired
	private MpServiceProfileRepository profileRepository;

	@Autowired
	private MpServiceActionRepository actionRepository;

	@Autowired
	private MpSessionRepository sessionRepository;

	@Autowired
	private MpSubscriptionRepository subscriptionRepository;

	@Autowired
	private MpUserEntitlementRepository entitlementRepository;

	@Autowired
	private MpAccessLogRepository accessLogRepository;

	@Autowired
	private FunctionalError functionalError;

	@Transactional(readOnly = true)
	public Response<ModuleCatalogDto> catalog(Locale locale) {
		Response<ModuleCatalogDto> response = new Response<>();
		List<MpModule> modules = moduleRepository.findByIsActiveTrueOrderBySortOrderAsc();
		List<ModuleCatalogDto> items = modules.stream().map(m -> {
			ModuleCatalogDto dto = new ModuleCatalogDto();
			dto.setCode(m.getCode());
			dto.setName(m.getName());
			dto.setDescription(m.getDescription());
			dto.setRoleModel(m.getRoleModel());
			dto.setParameters(moduleParamRepository
					.findByModule_IdAndIsActiveTrueOrderBySortOrderAscParamKeyAsc(m.getId())
					.stream()
					.map(p -> new ModuleCatalogDto.ParamDto(p.getParamKey(), p.getParamValue()))
					.toList());
			dto.setOpenAccessLevel(m.getOpenAccessLevel());
			dto.setDefaultActionLevel(m.getDefaultActionLevel());
			dto.setSortOrder(m.getSortOrder());
			List<ModuleCatalogDto.ServiceActionDto> actions = actionRepository
					.findByModule_CodeAndIsActiveTrue(m.getCode())
					.stream()
					.map(a -> {
						ModuleCatalogDto.ServiceActionDto ad = new ModuleCatalogDto.ServiceActionDto();
						ad.setCode(a.getCode());
						ad.setName(a.getName());
						ad.setAccessLevel(a.getAccessLevel());
						ad.setRequiredRole(a.getRequiredRole());
						return ad;
					})
					.toList();
			dto.setActions(actions);
			return dto;
		}).toList();
		response.setItems(items);
		response.setCount((long) items.size());
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional
	public Response<AccessDecisionDto> check(Request<AccessCheckDto> request, Locale locale) {
		Response<AccessDecisionDto> response = new Response<>();
		AccessCheckDto data = request != null ? request.getData() : null;
		if (data == null || data.getModuleCode() == null || data.getModuleCode().isBlank()) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("moduleCode", locale));
			return response;
		}

		String moduleCode = data.getModuleCode().trim();
		String actionCode = data.getActionCode() != null && !data.getActionCode().isBlank()
				? data.getActionCode().trim()
				: null;

		MpModule module = moduleRepository.findByCodeAndIsActiveTrue(moduleCode).orElse(null);
		if (module == null) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_EXIST("module", locale));
			return response;
		}

		String requiredLevel;
		MpServiceAction action = null;
		if (actionCode == null) {
			requiredLevel = module.getOpenAccessLevel();
		} else {
			action = actionRepository.findByModule_CodeAndCodeAndIsActiveTrue(moduleCode, actionCode).orElse(null);
			requiredLevel = action != null ? action.getAccessLevel() : module.getDefaultActionLevel();
		}

		MpSession session = resolveSession(data.getAccessToken());
		MpUser user = session != null ? session.getUser() : null;
		boolean authenticated = user != null;

		String requiredRole = action != null && action.getRequiredRole() != null
				? action.getRequiredRole()
				: "ANY";
		String userRole = ServiceProfileBusiness.ROLE_CLIENT;
		if (authenticated) {
			Optional<MpServiceProfile> profile = profileRepository
					.findByUser_IdAndModule_Code(user.getId(), moduleCode);
			if (profile.isPresent()) {
				userRole = profile.get().getCurrentRole();
			}
		}

		String roleForSub = "BUSINESS".equals(requiredRole)
				? ServiceProfileBusiness.ROLE_BUSINESS
				: ServiceProfileBusiness.ROLE_CLIENT;
		Optional<MpSubscription> scopedSub = Optional.empty();
		if (authenticated) {
			scopedSub = subscriptionRepository
					.findCurrentByUserModuleRole(user.getId(), moduleCode, roleForSub);
			if (scopedSub.isEmpty()) {
				// Legacy global mock sub (no module) still unlocks CLIENT actions.
				scopedSub = subscriptionRepository.findCurrentByUserId(user.getId())
						.filter(s -> s.getModule() == null
								|| moduleCode.equals(s.getModule().getCode()));
			}
		}
		boolean hasSub = scopedSub.isPresent() && isSubscriptionValid(scopedSub.get());
		String planCode = null;
		if (hasSub && scopedSub.get().getPlan() != null) {
			planCode = scopedSub.get().getPlan().getCode();
		}

		AccessDecisionDto decision = new AccessDecisionDto();
		decision.setModuleCode(moduleCode);
		decision.setActionCode(actionCode);
		decision.setRequiredLevel(requiredLevel);
		decision.setRequiredRole(requiredRole);
		decision.setUserRole(authenticated ? userRole : null);
		decision.setAuthenticated(authenticated);
		decision.setHasActiveSubscription(hasSub);
		decision.setPlanCode(planCode);

		boolean allowed;
		String reason;
		switch (requiredLevel) {
			case LEVEL_GUEST -> {
				allowed = true;
				reason = "guest_allowed";
			}
			case LEVEL_AUTH -> {
				allowed = authenticated;
				reason = authenticated ? "auth_ok" : "auth_required";
			}
			case LEVEL_SUBSCRIPTION -> {
				if (!authenticated) {
					allowed = false;
					reason = "auth_required";
				} else if (hasManualEntitlement(user, module, action)) {
					allowed = true;
					reason = "manual_entitlement";
				} else if (!roleAllows(requiredRole, userRole)) {
					allowed = false;
					reason = "business_role_required";
				} else if (hasSub) {
					allowed = true;
					reason = "subscription_active";
				} else {
					allowed = false;
					reason = "subscription_required";
				}
			}
			default -> {
				allowed = false;
				reason = "unknown_level";
			}
		}

		decision.setAllowed(allowed);
		decision.setReason(reason);
		logAccess(user, moduleCode, actionCode, requiredLevel, allowed, reason);

		response.setItem(decision);
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	/** BUSINESS can use CLIENT actions; CLIENT cannot use BUSINESS actions. */
	private static boolean roleAllows(String requiredRole, String userRole) {
		if (requiredRole == null || "ANY".equals(requiredRole)) {
			return true;
		}
		if ("CLIENT".equals(requiredRole)) {
			return "CLIENT".equals(userRole) || "BUSINESS".equals(userRole);
		}
		return requiredRole.equals(userRole);
	}

	private boolean hasManualEntitlement(MpUser user, MpModule module, MpServiceAction action) {
		List<MpUserEntitlement> ents = entitlementRepository.findValidByUserId(user.getId(), LocalDateTime.now());
		for (MpUserEntitlement e : ents) {
			if (action != null && e.getServiceAction() != null
					&& action.getId().equals(e.getServiceAction().getId())) {
				return true;
			}
			if (action == null && e.getModule() != null && module.getId().equals(e.getModule().getId())
					&& e.getServiceAction() == null) {
				return true;
			}
		}
		return false;
	}

	private boolean isSubscriptionValid(MpSubscription sub) {
		LocalDateTime now = LocalDateTime.now();
		if (sub.getEndAt() != null && sub.getEndAt().isBefore(now)) {
			return false;
		}
		return "TRIAL".equals(sub.getStatus()) || "ACTIVE".equals(sub.getStatus());
	}

	private MpSession resolveSession(String accessToken) {
		if (accessToken == null || accessToken.isBlank()) {
			return null;
		}
		return sessionRepository.findByAccessTokenAndRevokedFalse(accessToken.trim())
				.filter(s -> s.getExpiresAt().isAfter(LocalDateTime.now()))
				.orElse(null);
	}

	private void logAccess(MpUser user, String moduleCode, String actionCode, String level,
			boolean allowed, String reason) {
		MpAccessLog log = new MpAccessLog();
		log.setUser(user);
		log.setPhone(user != null ? user.getPhone() : null);
		log.setModuleCode(moduleCode);
		log.setActionCode(actionCode);
		log.setAccessLevel(level);
		log.setResult(allowed ? "ALLOW" : "DENY");
		log.setReason(reason);
		log.setCreatedAt(LocalDateTime.now());
		accessLogRepository.save(log);
	}
}
