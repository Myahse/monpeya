package com.monpeya.backend.api.controller;

import java.util.Locale;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.monpeya.backend.api.contracts.Request;
import com.monpeya.backend.api.contracts.Response;
import com.monpeya.backend.api.dto.AccessCheckDto;
import com.monpeya.backend.api.dto.AccessDecisionDto;
import com.monpeya.backend.api.dto.ModuleCatalogDto;
import com.monpeya.backend.api.dto.PlanDto;
import com.monpeya.backend.api.dto.PlansQueryDto;
import com.monpeya.backend.api.dto.ServiceProfileDto;
import com.monpeya.backend.api.dto.ServiceProfileRequestDto;
import com.monpeya.backend.api.dto.SubscribeDto;
import com.monpeya.backend.api.dto.SubscriptionDto;
import com.monpeya.backend.api.dto.SubscriptionRequestActionDto;
import com.monpeya.backend.api.dto.SubscriptionRequestDto;
import com.monpeya.backend.api.service.AccessBusiness;
import com.monpeya.backend.api.service.ServiceProfileBusiness;
import com.monpeya.backend.api.service.SubscriptionBusiness;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/v1")
@Tag(name = "Access & Subscriptions", description = "Guest / auth / subscription gates for the super-app")
public class AccessController {

	@Autowired
	private AccessBusiness accessBusiness;

	@Autowired
	private SubscriptionBusiness subscriptionBusiness;

	@Autowired
	private ServiceProfileBusiness serviceProfileBusiness;

	@PostMapping("/modules/catalog")
	@Operation(summary = "List services (name + parameters + roleModel) and gated actions")
	public ResponseEntity<Response<ModuleCatalogDto>> catalog(Locale locale) {
		return ok(accessBusiness.catalog(locale));
	}

	@PostMapping("/access/check")
	@Operation(summary = "Check if guest or user may open a module / call a service action")
	public ResponseEntity<Response<AccessDecisionDto>> check(
			@RequestBody(required = false) Request<AccessCheckDto> request,
			Locale locale) {
		return ok(accessBusiness.check(request != null ? request : new Request<>(), locale));
	}

	@PostMapping("/plans")
	@Operation(summary = "List subscription plans (optional moduleCode filter)")
	public ResponseEntity<Response<PlanDto>> plans(
			@RequestBody(required = false) Request<PlansQueryDto> request,
			Locale locale) {
		return ok(subscriptionBusiness.listPlans(
				request != null ? request : new Request<>(), locale));
	}

	@PostMapping("/subscriptions/me")
	@Operation(summary = "Current subscriptions (optional moduleCode / role filter)")
	public ResponseEntity<Response<SubscriptionDto>> mySubscription(
			@RequestBody Request<SubscribeDto> request,
			Locale locale) {
		Response<SubscriptionDto> response = subscriptionBusiness.mySubscription(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.UNAUTHORIZED : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	@PostMapping("/subscriptions/subscribe")
	@Operation(summary = "CLIENT straight debit subscribe (requires déplafonné)")
	public ResponseEntity<Response<SubscriptionDto>> subscribe(
			@RequestBody Request<SubscribeDto> request,
			Locale locale) {
		Response<SubscriptionDto> response = subscriptionBusiness.subscribe(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	@PostMapping("/subscriptions/requests/business")
	@Operation(summary = "BUSINESS: debit + submit plan request (WAITING_FOR_APPROVAL)")
	public ResponseEntity<Response<SubscriptionRequestDto>> businessRequest(
			@RequestBody Request<SubscriptionRequestActionDto> request,
			Locale locale) {
		Response<SubscriptionRequestDto> response = subscriptionBusiness.createBusinessRequest(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	@PostMapping("/subscriptions/requests/deplafonnement")
	@Operation(summary = "CLIENT: request to be déplafonné before subscribe debit")
	public ResponseEntity<Response<SubscriptionRequestDto>> deplafonnementRequest(
			@RequestBody Request<SubscriptionRequestActionDto> request,
			Locale locale) {
		Response<SubscriptionRequestDto> response =
				subscriptionBusiness.createDeplafonnementRequest(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	@PostMapping("/subscriptions/requests/me")
	@Operation(summary = "List my subscription / déplafonnement requests")
	public ResponseEntity<Response<SubscriptionRequestDto>> myRequests(
			@RequestBody Request<SubscriptionRequestActionDto> request,
			Locale locale) {
		Response<SubscriptionRequestDto> response = subscriptionBusiness.listMyRequests(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.UNAUTHORIZED : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	@PostMapping("/subscriptions/requests/review")
	@Operation(summary = "Review request: APPROVE | REJECT | ON_REVIEW (shell)")
	public ResponseEntity<Response<SubscriptionRequestDto>> reviewRequest(
			@RequestBody Request<SubscriptionRequestActionDto> request,
			Locale locale) {
		Response<SubscriptionRequestDto> response = subscriptionBusiness.reviewRequest(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	@PostMapping("/services/profiles/me")
	@Operation(summary = "Per-service CLIENT/BUSINESS profiles (Leadway stays client-only)")
	public ResponseEntity<Response<ServiceProfileDto>> serviceProfiles(
			@RequestBody Request<ServiceProfileRequestDto> request,
			Locale locale) {
		Response<ServiceProfileDto> response = serviceProfileBusiness.listMine(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.UNAUTHORIZED : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	@PostMapping("/services/profiles/get")
	@Operation(summary = "One service profile by moduleCode")
	public ResponseEntity<Response<ServiceProfileDto>> serviceProfileGet(
			@RequestBody Request<ServiceProfileRequestDto> request,
			Locale locale) {
		Response<ServiceProfileDto> response = serviceProfileBusiness.getOne(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	@PostMapping("/services/business/upgrade")
	@Operation(summary = "Start business upgrade (DOCUMENTS or PEYAPAY_MERCHANT)")
	public ResponseEntity<Response<ServiceProfileDto>> businessUpgrade(
			@RequestBody Request<ServiceProfileRequestDto> request,
			Locale locale) {
		Response<ServiceProfileDto> response = serviceProfileBusiness.startBusinessUpgrade(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	@PostMapping("/services/business/documents")
	@Operation(summary = "Register a business upgrade document (ID card, etc.)")
	public ResponseEntity<Response<ServiceProfileDto>> businessDocument(
			@RequestBody Request<ServiceProfileRequestDto> request,
			Locale locale) {
		Response<ServiceProfileDto> response = serviceProfileBusiness.addDocument(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	private static <T> ResponseEntity<Response<T>> ok(Response<T> response) {
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}
}
