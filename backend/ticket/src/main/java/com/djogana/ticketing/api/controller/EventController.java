package com.djogana.ticketing.api.controller;

import java.util.Locale;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.CannotCreateTransactionException;
import org.springframework.transaction.TransactionSystemException;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.djogana.ticketing.api.contracts.ExceptionUtils;
import com.djogana.ticketing.api.contracts.Request;
import com.djogana.ticketing.api.contracts.Response;
import com.djogana.ticketing.api.dto.EventActionDto;
import com.djogana.ticketing.api.dto.EventCreateDto;
import com.djogana.ticketing.api.dto.EventDto;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.EventActionRequest;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.EventCreateRequest;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.PublicEventsRequest;
import com.djogana.ticketing.api.service.EventBusiness;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/v1/events")
@Tag(name = "Events", description = "Event lifecycle: create, publish, list, get")
public class EventController {

	@Autowired
	private EventBusiness eventBusiness;

	@Autowired
	private ExceptionUtils exceptionUtils;

	@PostMapping("/create")
	@Operation(summary = "Create event", description = "Creates a new event in **DRAFT** status. Response includes generated `eventCode`.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = EventCreateRequest.class)))
	public ResponseEntity<Response<EventDto>> create(@RequestBody Request<EventCreateDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> eventBusiness.create(request, locale)));
	}

	@PostMapping("/publish")
	@Operation(summary = "Publish event", description = "Publishes a **DRAFT** event by `eventCode` (creator `codeClient` required). Moves generated tickets to **FOR_SALE**.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = EventActionRequest.class)))
	public ResponseEntity<Response<EventDto>> publish(@RequestBody Request<EventActionDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> eventBusiness.publish(request, locale)));
	}

	@PostMapping("/public")
	@Operation(summary = "List published events", description = "Returns all events with status **PUBLISHED**, ordered by start date.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = false,
			content = @Content(schema = @Schema(implementation = PublicEventsRequest.class)))
	public ResponseEntity<Response<EventDto>> listPublic(@RequestBody(required = false) Request<Map<String, Object>> request,
			Locale locale) {
		return ApiResponses.of(run(locale, () -> eventBusiness.listPublic(locale)));
	}

	@PostMapping("/get")
	@Operation(summary = "Get event by code", description = "Returns event details for the given `eventCode`.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = EventActionRequest.class)))
	public ResponseEntity<Response<EventDto>> getByCode(@RequestBody Request<EventActionDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> eventBusiness.getByCode(request, locale)));
	}

	private <T> Response<T> run(Locale locale, BusinessCall<T> call) {
		Response<T> response = new Response<>();
		Locale effective = locale != null ? locale : Locale.getDefault();
		try {
			return call.execute();
		} catch (CannotCreateTransactionException e) {
			exceptionUtils.CANNOT_CREATE_TRANSACTION_EXCEPTION(response, effective, e);
		} catch (TransactionSystemException e) {
			exceptionUtils.TRANSACTION_SYSTEM_EXCEPTION(response, effective, e);
		} catch (RuntimeException e) {
			exceptionUtils.RUNTIME_EXCEPTION(response, effective, e);
		} catch (Exception e) {
			exceptionUtils.EXCEPTION(response, effective, e);
		}
		return response;
	}

	@FunctionalInterface
	private interface BusinessCall<T> {
		Response<T> execute() throws Exception;
	}
}
