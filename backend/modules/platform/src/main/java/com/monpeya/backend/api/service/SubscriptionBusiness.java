package com.monpeya.backend.api.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.monpeya.backend.api.config.SubscriptionPricingProperties;
import com.monpeya.backend.api.config.SubscriptionPricingProperties.PlanPrice;
import com.monpeya.backend.api.contracts.FunctionalError;
import com.monpeya.backend.api.contracts.Request;
import com.monpeya.backend.api.contracts.Response;
import com.monpeya.backend.api.dto.PlanDto;
import com.monpeya.backend.api.dto.PlansQueryDto;
import com.monpeya.backend.api.dto.SubscribeDto;
import com.monpeya.backend.api.dto.SubscriptionDto;
import com.monpeya.backend.api.dto.SubscriptionRequestActionDto;
import com.monpeya.backend.api.dto.SubscriptionRequestDto;
import com.monpeya.backend.api.entity.MpModule;
import com.monpeya.backend.api.entity.MpPlan;
import com.monpeya.backend.api.entity.MpPlanFeature;
import com.monpeya.backend.api.entity.MpServiceProfile;
import com.monpeya.backend.api.entity.MpSession;
import com.monpeya.backend.api.entity.MpSubscription;
import com.monpeya.backend.api.entity.MpSubscriptionRequest;
import com.monpeya.backend.api.entity.MpUser;
import com.monpeya.backend.api.repository.MpModuleRepository;
import com.monpeya.backend.api.repository.MpPlanFeatureRepository;
import com.monpeya.backend.api.repository.MpPlanRepository;
import com.monpeya.backend.api.repository.MpServiceProfileRepository;
import com.monpeya.backend.api.repository.MpSessionRepository;
import com.monpeya.backend.api.repository.MpSubscriptionRepository;
import com.monpeya.backend.api.repository.MpSubscriptionRequestRepository;
import com.monpeya.backend.api.repository.MpUserRepository;

@Service
public class SubscriptionBusiness {

	public static final String PLAN_KIND_SINGLE = "SINGLE";
	public static final String PLAN_KIND_GROUPED = "GROUPED";

	public static final String REQ_BUSINESS_SUBSCRIBE = "BUSINESS_SUBSCRIBE";
	public static final String REQ_DEPLAFONNEMENT = "DEPLAFONNEMENT";

	public static final String ST_WAITING = "WAITING_FOR_APPROVAL";
	public static final String ST_ON_REVIEW = "ON_REVIEW";
	public static final String ST_APPROVED = "APPROVED";
	public static final String ST_REJECTED = "REJECTED";

	@Autowired
	private MpPlanRepository planRepository;

	@Autowired
	private MpPlanFeatureRepository planFeatureRepository;

	@Autowired
	private MpSubscriptionRepository subscriptionRepository;

	@Autowired
	private MpSubscriptionRequestRepository requestRepository;

	@Autowired
	private MpSessionRepository sessionRepository;

	@Autowired
	private MpModuleRepository moduleRepository;

	@Autowired
	private MpServiceProfileRepository profileRepository;

	@Autowired
	private MpUserRepository userRepository;

	@Autowired
	private SubscriptionPricingProperties pricingProperties;

	@Autowired
	private FunctionalError functionalError;

	@Transactional(readOnly = true)
	public Response<PlanDto> listPlans(Request<PlansQueryDto> request, Locale locale) {
		Response<PlanDto> response = new Response<>();
		PlansQueryDto data = request != null ? request.getData() : null;
		String roleFilter = data != null && data.getRole() != null && !data.getRole().isBlank()
				? data.getRole().trim().toUpperCase()
				: null;

		// Prices come from .env / application.properties (not ticket prices).
		List<PlanDto> items = new java.util.ArrayList<>();
		items.add(toEnvPlanDto(pricingProperties.getClient(), ServiceProfileBusiness.ROLE_CLIENT));
		items.add(toEnvPlanDto(pricingProperties.getBusiness(), ServiceProfileBusiness.ROLE_BUSINESS));
		if (roleFilter != null) {
			items = items.stream().filter(p -> roleFilter.equals(p.getRole())).toList();
		}
		response.setItems(items);
		response.setCount((long) items.size());
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional(readOnly = true)
	public Response<SubscriptionDto> mySubscription(Request<SubscribeDto> request, Locale locale) {
		Response<SubscriptionDto> response = new Response<>();
		MpUser user = requireUser(request, response, locale);
		if (user == null) {
			return response;
		}

		SubscribeDto data = request != null ? request.getData() : null;
		String moduleCode = data != null && data.getModuleCode() != null && !data.getModuleCode().isBlank()
				? data.getModuleCode().trim()
				: null;
		String role = normalizeRole(data != null ? data.getRole() : null);

		if (moduleCode != null) {
			var list = role != null
					? subscriptionRepository.findActiveByUserModuleRole(user.getId(), moduleCode, role)
					: subscriptionRepository.findActiveByUserModule(user.getId(), moduleCode);
			response.setItems(list.stream().map(this::toSubDto).toList());
			response.setCount((long) list.size());
			if (!list.isEmpty()) {
				response.setItem(toSubDto(list.get(0)));
			}
		} else {
			var list = subscriptionRepository.findActiveByUserId(user.getId());
			response.setItems(list.stream().map(this::toSubDto).toList());
			response.setCount((long) list.size());
			if (!list.isEmpty()) {
				response.setItem(toSubDto(list.get(0)));
			}
		}
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS(
				response.getItem() == null ? "no active subscription" : "", locale));
		return response;
	}

	/**
	 * CLIENT only: straight mock debit subscribe.
	 * Requires déplafonné; otherwise client must call déplafonnement request first.
	 * BUSINESS must use {@link #createBusinessRequest} (debit + approval workflow).
	 */
	@Transactional
	public Response<SubscriptionDto> subscribe(Request<SubscribeDto> request, Locale locale) {
		Response<SubscriptionDto> response = new Response<>();
		SubscribeDto data = request != null ? request.getData() : null;
		MpUser user = requireUser(request, response, locale);
		if (user == null) {
			return response;
		}

		String role = normalizeRole(data != null ? data.getRole() : null);
		if (role == null) {
			role = ServiceProfileBusiness.ROLE_CLIENT;
		}
		if (ServiceProfileBusiness.ROLE_BUSINESS.equals(role)) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL(
					"BUSINESS must submit a subscription request (debited then approved)", locale));
			return response;
		}

		if (!Boolean.TRUE.equals(user.getIsDeplafonne())) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL(
					"client not déplafonné — submit déplafonnement request first", locale));
			return response;
		}

		String planCode = data != null && data.getPlanCode() != null && !data.getPlanCode().isBlank()
				? data.getPlanCode().trim()
				: pricingProperties.getClient().getCode();
		MpPlan plan = resolveOrSyncEnvPlan(planCode, ServiceProfileBusiness.ROLE_CLIENT, response, locale);
		if (response.isHasError() || plan == null) {
			return response;
		}

		Set<MpModule> modules = resolveModulesForSubscribe(data, plan, response, locale);
		if (response.isHasError()) {
			return response;
		}
		if (modules.isEmpty()) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("moduleCode or planCode", locale));
			return response;
		}

		LocalDateTime now = LocalDateTime.now();
		String paymentRef = mockPaymentRef();
		BigDecimal amount = pricingProperties.getClient().getPrice();
		MpSubscription primary = null;
		for (MpModule module : modules) {
			subscriptionRepository.findActiveByUserModuleRole(user.getId(), module.getCode(), role)
					.forEach(this::cancel);
			MpSubscription sub = activateSubscription(user, module, plan, role, paymentRef, now);
			if (primary == null) {
				primary = sub;
			}
		}

		response.setItem(toSubDto(primary));
		response.setItems(List.of(toSubDto(primary)));
		response.setCount(1L);
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS(
				"client debit applied (mock) amount=" + amount + " " + pricingProperties.getCurrency(),
				locale));
		return response;
	}

	/**
	 * BUSINESS: launch request with plan + amount, mock-debit immediately,
	 * status WAITING_FOR_APPROVAL until review.
	 */
	@Transactional
	public Response<SubscriptionRequestDto> createBusinessRequest(
			Request<SubscriptionRequestActionDto> request, Locale locale) {
		Response<SubscriptionRequestDto> response = new Response<>();
		SubscriptionRequestActionDto data = request != null ? request.getData() : null;
		MpUser user = requireUserFromAction(request, response, locale);
		if (user == null) {
			return response;
		}

		String planCode = data != null && data.getPlanCode() != null && !data.getPlanCode().isBlank()
				? data.getPlanCode().trim()
				: pricingProperties.getBusiness().getCode();
		MpPlan plan = resolveOrSyncEnvPlan(planCode, ServiceProfileBusiness.ROLE_BUSINESS, response, locale);
		if (response.isHasError() || plan == null) {
			return response;
		}

		SubscribeDto moduleProbe = new SubscribeDto();
		if (data != null) {
			moduleProbe.setModuleCode(data.getModuleCode());
			moduleProbe.setPlanCode(plan.getCode());
		}
		Set<MpModule> modules = resolveModulesForSubscribe(moduleProbe, plan, response, locale);
		if (response.isHasError() || modules.isEmpty()) {
			if (!response.isHasError()) {
				response.setHasError(true);
				response.setStatus(functionalError.FIELD_EMPTY("moduleCode or plan features", locale));
			}
			return response;
		}

		for (MpModule module : modules) {
			if (ServiceProfileBusiness.MODEL_CLIENT_ONLY.equals(module.getRoleModel())) {
				response.setHasError(true);
				response.setStatus(functionalError.AUTH_FAIL(
						"this service is client-only (e.g. Leadway)", locale));
				return response;
			}
			MpServiceProfile profile = profileRepository
					.findByUser_IdAndModule_Code(user.getId(), module.getCode())
					.orElse(null);
			// Identity step first (docs / PeyaPay merchant) must be APPROVED before paid request.
			if (profile == null || !"APPROVED".equals(profile.getBusinessStatus())) {
				response.setHasError(true);
				response.setStatus(functionalError.AUTH_FAIL(
						"business upgrade required (documents or PeyaPay merchant) before request",
						locale));
				return response;
			}
		}

		if (!requestRepository.findOpenByUserAndType(user.getId(), REQ_BUSINESS_SUBSCRIBE).isEmpty()) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL(
					"open BUSINESS subscription request already exists", locale));
			return response;
		}

		// Amount always from .env / properties (client cannot override price).
		BigDecimal amount = pricingProperties.getBusiness().getPrice();
		LocalDateTime now = LocalDateTime.now();
		MpModule primaryModule = modules.iterator().next();

		MpSubscriptionRequest req = new MpSubscriptionRequest();
		req.setUser(user);
		req.setModule(primaryModule);
		req.setPlan(plan);
		req.setRole(ServiceProfileBusiness.ROLE_BUSINESS);
		req.setRequestType(REQ_BUSINESS_SUBSCRIBE);
		req.setAmount(amount != null ? amount : BigDecimal.ZERO);
		req.setCurrency(pricingProperties.getCurrency());
		req.setStatus(ST_WAITING);
		req.setPaymentProvider("PEYAPAY");
		req.setPaymentStatus("MOCK_PAID");
		req.setIsMockPayment(true);
		req.setPaymentRef(mockPaymentRef());
		req.setDebitedAt(now);
		req.setCreatedAt(now);
		req.setUpdatedAt(now);
		req = requestRepository.save(req);

		response.setItem(toRequestDto(req));
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS(
				"debited (mock); waiting for approval", locale));
		return response;
	}

	/** CLIENT not déplafonné: open déplafonnement request (no plan debit). */
	@Transactional
	public Response<SubscriptionRequestDto> createDeplafonnementRequest(
			Request<SubscriptionRequestActionDto> request, Locale locale) {
		Response<SubscriptionRequestDto> response = new Response<>();
		MpUser user = requireUserFromAction(request, response, locale);
		if (user == null) {
			return response;
		}
		if (Boolean.TRUE.equals(user.getIsDeplafonne())) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL("already déplafonné", locale));
			return response;
		}
		if (!requestRepository.findOpenByUserAndType(user.getId(), REQ_DEPLAFONNEMENT).isEmpty()) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL(
					"open déplafonnement request already exists", locale));
			return response;
		}

		LocalDateTime now = LocalDateTime.now();
		MpSubscriptionRequest req = new MpSubscriptionRequest();
		req.setUser(user);
		req.setRole(ServiceProfileBusiness.ROLE_CLIENT);
		req.setRequestType(REQ_DEPLAFONNEMENT);
		req.setAmount(BigDecimal.ZERO);
		req.setCurrency("XOF");
		req.setStatus(ST_WAITING);
		req.setPaymentProvider("PEYAPAY");
		req.setPaymentStatus("NONE");
		req.setIsMockPayment(true);
		req.setCreatedAt(now);
		req.setUpdatedAt(now);
		req = requestRepository.save(req);

		response.setItem(toRequestDto(req));
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("déplafonnement request submitted", locale));
		return response;
	}

	@Transactional(readOnly = true)
	public Response<SubscriptionRequestDto> listMyRequests(
			Request<SubscriptionRequestActionDto> request, Locale locale) {
		Response<SubscriptionRequestDto> response = new Response<>();
		MpUser user = requireUserFromAction(request, response, locale);
		if (user == null) {
			return response;
		}
		List<SubscriptionRequestDto> items = requestRepository
				.findByUser_IdOrderByCreatedAtDesc(user.getId())
				.stream()
				.map(this::toRequestDto)
				.toList();
		response.setItems(items);
		response.setCount((long) items.size());
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	/**
	 * Shell review: APPROVE | REJECT | ON_REVIEW.
	 * APPROVE BUSINESS → activate subscription; APPROVE DEPLAFONNEMENT → mark user déplafonné.
	 */
	@Transactional
	public Response<SubscriptionRequestDto> reviewRequest(
			Request<SubscriptionRequestActionDto> request, Locale locale) {
		Response<SubscriptionRequestDto> response = new Response<>();
		SubscriptionRequestActionDto data = request != null ? request.getData() : null;
		MpUser actor = requireUserFromAction(request, response, locale);
		if (actor == null) {
			return response;
		}
		if (data == null || data.getRequestId() == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("requestId", locale));
			return response;
		}
		String decision = data.getDecision() != null ? data.getDecision().trim().toUpperCase() : "";
		MpSubscriptionRequest req = requestRepository.findById(data.getRequestId()).orElse(null);
		if (req == null) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_EXIST("request", locale));
			return response;
		}
		if (ST_APPROVED.equals(req.getStatus()) || ST_REJECTED.equals(req.getStatus())) {
			response.setHasError(true);
			response.setStatus(functionalError.AUTH_FAIL("request already closed", locale));
			return response;
		}

		LocalDateTime now = LocalDateTime.now();
		req.setReviewNote(data.getReviewNote());
		req.setUpdatedAt(now);
		switch (decision) {
			case "ON_REVIEW" -> req.setStatus(ST_ON_REVIEW);
			case "REJECT", "REJECTED" -> {
				req.setStatus(ST_REJECTED);
				req.setReviewedAt(now);
			}
			case "APPROVE", "APPROVED" -> {
				req.setStatus(ST_APPROVED);
				req.setReviewedAt(now);
				if (REQ_DEPLAFONNEMENT.equals(req.getRequestType())) {
					MpUser u = req.getUser();
					u.setIsDeplafonne(true);
					u.setUpdatedAt(now);
					userRepository.save(u);
				} else if (REQ_BUSINESS_SUBSCRIBE.equals(req.getRequestType())) {
					MpSubscription sub = activateSubscription(
							req.getUser(),
							req.getModule(),
							req.getPlan(),
							ServiceProfileBusiness.ROLE_BUSINESS,
							req.getPaymentRef() != null ? req.getPaymentRef() : mockPaymentRef(),
							now);
					req.setSubscription(sub);
					if (req.getModule() != null) {
						profileRepository
								.findByUser_IdAndModule_Code(req.getUser().getId(), req.getModule().getCode())
								.ifPresent(profile -> {
									profile.setCurrentRole(ServiceProfileBusiness.ROLE_BUSINESS);
									profile.setUpdatedAt(now);
									profileRepository.save(profile);
								});
					}
				}
			}
			default -> {
				response.setHasError(true);
				response.setStatus(functionalError.FIELD_EMPTY("decision", locale));
				return response;
			}
		}
		req = requestRepository.save(req);
		response.setItem(toRequestDto(req));
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS(req.getStatus(), locale));
		return response;
	}

	private MpSubscription activateSubscription(
			MpUser user, MpModule module, MpPlan plan, String role, String paymentRef, LocalDateTime now) {
		if (module != null) {
			subscriptionRepository.findActiveByUserModuleRole(user.getId(), module.getCode(), role)
					.forEach(this::cancel);
		}
		MpSubscription sub = new MpSubscription();
		sub.setUser(user);
		sub.setPlan(plan);
		sub.setModule(module);
		sub.setRole(role);
		sub.setStatus("ACTIVE");
		sub.setStartAt(now);
		sub.setEndAt(now.plus(30, ChronoUnit.DAYS));
		sub.setAutoRenew(false);
		sub.setPaymentProvider("PEYAPAY");
		sub.setPaymentStatus("MOCK_PAID");
		sub.setIsMockPayment(true);
		sub.setPaymentRef(paymentRef);
		sub.setCreatedAt(now);
		sub.setUpdatedAt(now);
		return subscriptionRepository.save(sub);
	}

	/**
	 * Resolve plan by code; if it matches .env CLIENT/BUSINESS codes, upsert DB row with env price.
	 */
	private MpPlan resolveOrSyncEnvPlan(String planCode, String role, Response<?> response, Locale locale) {
		PlanPrice envPlan = pricingProperties.planForRole(role);
		String code = planCode != null && !planCode.isBlank() ? planCode.trim() : envPlan.getCode();
		if (!code.equalsIgnoreCase(pricingProperties.getClient().getCode())
				&& !code.equalsIgnoreCase(pricingProperties.getBusiness().getCode())) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_EXIST("plan", locale));
			return null;
		}
		if (code.equalsIgnoreCase(pricingProperties.getBusiness().getCode())) {
			envPlan = pricingProperties.getBusiness();
		} else {
			envPlan = pricingProperties.getClient();
		}

		MpPlan plan = planRepository.findByCodeAndIsActiveTrue(envPlan.getCode()).orElse(null);
		LocalDateTime now = LocalDateTime.now();
		if (plan == null) {
			plan = new MpPlan();
			plan.setCode(envPlan.getCode());
			plan.setCreatedAt(now);
		}
		plan.setName(envPlan.getName());
		plan.setDescription(envPlan.getDescription());
		plan.setPrice(envPlan.getPrice());
		plan.setCurrency(pricingProperties.getCurrency());
		plan.setBillingPeriod("MONTHLY");
		plan.setTrialDays(0);
		plan.setIsDefault(ServiceProfileBusiness.ROLE_CLIENT.equals(role));
		plan.setIsActive(true);
		plan.setUpdatedAt(now);
		return planRepository.save(plan);
	}

	private PlanDto toEnvPlanDto(PlanPrice plan, String role) {
		PlanDto dto = new PlanDto();
		dto.setCode(plan.getCode());
		dto.setName(plan.getName());
		dto.setDescription(plan.getDescription());
		dto.setPrice(plan.getPrice());
		dto.setCurrency(pricingProperties.getCurrency());
		dto.setBillingPeriod("MONTHLY");
		dto.setTrialDays(0);
		dto.setIsDefault(ServiceProfileBusiness.ROLE_CLIENT.equals(role));
		dto.setRole(role);
		dto.setPlanKind(PLAN_KIND_SINGLE);
		dto.setModuleCodes(List.of());
		return dto;
	}

	private static String mockPaymentRef() {
		return "MOCK-" + UUID.randomUUID().toString().replace("-", "").substring(0, 16).toUpperCase();
	}

	private SubscriptionRequestDto toRequestDto(MpSubscriptionRequest req) {
		SubscriptionRequestDto dto = new SubscriptionRequestDto();
		dto.setRequestId(req.getId());
		dto.setRequestType(req.getRequestType());
		if (req.getModule() != null) {
			dto.setModuleCode(req.getModule().getCode());
		}
		dto.setRole(req.getRole());
		if (req.getPlan() != null) {
			dto.setPlanCode(req.getPlan().getCode());
			dto.setPlanName(req.getPlan().getName());
		}
		dto.setAmount(req.getAmount());
		dto.setCurrency(req.getCurrency());
		dto.setStatus(req.getStatus());
		dto.setPaymentStatus(req.getPaymentStatus());
		dto.setPaymentRef(req.getPaymentRef());
		dto.setIsMockPayment(req.getIsMockPayment());
		dto.setDebitedAt(req.getDebitedAt());
		dto.setReviewedAt(req.getReviewedAt());
		dto.setReviewNote(req.getReviewNote());
		if (req.getSubscription() != null) {
			dto.setSubscriptionId(req.getSubscription().getId());
		}
		dto.setCreatedAt(req.getCreatedAt());
		return dto;
	}

	private MpUser requireUserFromAction(
			Request<SubscriptionRequestActionDto> request, Response<?> response, Locale locale) {
		SubscriptionRequestActionDto data = request != null ? request.getData() : null;
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

	private Set<MpModule> resolveModulesForSubscribe(
			SubscribeDto data,
			MpPlan plan,
			Response<?> response,
			Locale locale) {
		Set<MpModule> modules = new LinkedHashSet<>();
		if (plan != null) {
			List<MpPlanFeature> features = planFeatureRepository.findByPlan_Id(plan.getId());
			for (MpPlanFeature feature : features) {
				if (feature.getModule() != null && Boolean.TRUE.equals(feature.getModule().getIsActive())) {
					modules.add(feature.getModule());
				}
			}
		}
		String moduleCode = data != null && data.getModuleCode() != null && !data.getModuleCode().isBlank()
				? data.getModuleCode().trim()
				: null;
		if (moduleCode != null) {
			MpModule module = moduleRepository.findByCodeAndIsActiveTrue(moduleCode).orElse(null);
			if (module == null) {
				response.setHasError(true);
				response.setStatus(functionalError.DATA_NOT_EXIST("module", locale));
				return modules;
			}
			modules.add(module);
		}
		return modules;
	}

	private void cancel(MpSubscription s) {
		s.setStatus("CANCELLED");
		s.setCancelledAt(LocalDateTime.now());
		s.setUpdatedAt(LocalDateTime.now());
		subscriptionRepository.save(s);
	}

	private MpUser requireUser(Request<SubscribeDto> request, Response<?> response, Locale locale) {
		SubscribeDto data = request != null ? request.getData() : null;
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

	private static String normalizeRole(String role) {
		if (role == null || role.isBlank()) {
			return null;
		}
		String r = role.trim().toUpperCase();
		if (ServiceProfileBusiness.ROLE_CLIENT.equals(r) || ServiceProfileBusiness.ROLE_BUSINESS.equals(r)) {
			return r;
		}
		return null;
	}

	private PlanDto toPlanDto(MpPlan plan) {
		PlanDto dto = new PlanDto();
		dto.setCode(plan.getCode());
		dto.setName(plan.getName());
		dto.setDescription(plan.getDescription());
		dto.setPrice(plan.getPrice());
		dto.setCurrency(plan.getCurrency());
		dto.setBillingPeriod(plan.getBillingPeriod());
		dto.setTrialDays(plan.getTrialDays());
		dto.setIsDefault(plan.getIsDefault());

		List<MpPlanFeature> features = planFeatureRepository.findByPlan_Id(plan.getId());
		List<String> moduleCodes = features.stream()
				.filter(f -> f.getModule() != null && f.getModule().getCode() != null)
				.map(f -> f.getModule().getCode())
				.distinct()
				.toList();
		dto.setModuleCodes(moduleCodes);
		dto.setPlanKind(moduleCodes.size() > 1 ? PLAN_KIND_GROUPED : PLAN_KIND_SINGLE);
		return dto;
	}

	private SubscriptionDto toSubDto(MpSubscription sub) {
		SubscriptionDto dto = new SubscriptionDto();
		dto.setSubscriptionId(sub.getId());
		if (sub.getModule() != null) {
			dto.setModuleCode(sub.getModule().getCode());
		}
		dto.setRole(sub.getRole());
		if (sub.getPlan() != null) {
			dto.setPlanCode(sub.getPlan().getCode());
			dto.setPlanName(sub.getPlan().getName());
		}
		dto.setStatus(sub.getStatus());
		dto.setStartAt(sub.getStartAt());
		dto.setEndAt(sub.getEndAt());
		dto.setTrialEndAt(sub.getTrialEndAt());
		dto.setAutoRenew(sub.getAutoRenew());
		dto.setPaymentProvider(sub.getPaymentProvider());
		dto.setPaymentStatus(sub.getPaymentStatus());
		dto.setPaymentRef(sub.getPaymentRef());
		dto.setIsMockPayment(sub.getIsMockPayment());
		return dto;
	}
}
