package com.djogana.ticketing.api.controller;

import java.util.Locale;

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
import com.djogana.ticketing.api.dto.CodeClientDto;
import com.djogana.ticketing.api.dto.CreatorDashboardResultDto;
import com.djogana.ticketing.api.dto.TicketDto;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.CodeClientRequest;
import com.djogana.ticketing.api.service.TicketBusiness;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/v1/dashboard/creator")
@Tag(name = "Creator dashboard", description = "Stats and ticket lists for event creators")
public class DashboardController {

	@Autowired
	private TicketBusiness ticketBusiness;

	@Autowired
	private ExceptionUtils exceptionUtils;

	@PostMapping("/summary")
	@Operation(summary = "Creator summary", description = "Aggregated stats and event list for the creator `codeClient`.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = CodeClientRequest.class)))
	public ResponseEntity<Response<CreatorDashboardResultDto>> summary(
			@RequestBody Request<CodeClientDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> ticketBusiness.creatorDashboard(request, locale)));
	}

	@PostMapping("/tickets")
	@Operation(summary = "Creator tickets", description = "All tickets across events created by `codeClient`.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = CodeClientRequest.class)))
	public ResponseEntity<Response<TicketDto>> tickets(@RequestBody Request<CodeClientDto> request,
			Locale locale) {
		return ApiResponses.of(run(locale, () -> ticketBusiness.creatorTickets(request, locale)));
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
