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
import com.djogana.ticketing.api.dto.BuyTicketDto;
import com.djogana.ticketing.api.dto.CodeClientDto;
import com.djogana.ticketing.api.dto.ConsumeTicketDto;
import com.djogana.ticketing.api.dto.GenerateTicketsDto;
import com.djogana.ticketing.api.dto.QrActionDto;
import com.djogana.ticketing.api.dto.TicketActionDto;
import com.djogana.ticketing.api.dto.TicketDto;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.BuyTicketRequest;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.CodeClientRequest;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.ConsumeTicketRequest;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.GenerateTicketsRequest;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.QrActionRequest;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.TicketActionRequest;
import com.djogana.ticketing.api.service.TicketBusiness;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/v1/tickets")
@Tag(name = "Tickets", description = "Tickets by ticketCode — events, transport/conductor, passes")
public class TicketController {

	@Autowired
	private TicketBusiness ticketBusiness;

	@Autowired
	private ExceptionUtils exceptionUtils;

	@PostMapping("/generate")
	@Operation(summary = "Generate tickets", description = "Event tickets: set `eventCode`. Standalone (conductor, pass, etc.): omit `eventCode`, set `purpose`, `title`, `validFrom`, `price`.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = GenerateTicketsRequest.class)))
	public ResponseEntity<Response<TicketDto>> generate(@RequestBody Request<GenerateTicketsDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> ticketBusiness.generate(request, locale)));
	}

	@PostMapping("/buy")
	@Operation(summary = "Buy ticket", description = "Purchases a **FOR_SALE** ticket by `ticketCode`.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = BuyTicketRequest.class)))
	public ResponseEntity<Response<TicketDto>> buy(@RequestBody Request<BuyTicketDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> ticketBusiness.buy(request, locale)));
	}

	@PostMapping("/verify")
	@Operation(summary = "Verify QR", description = "Validates QR signature and returns ticket details (no state change).")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = QrActionRequest.class)))
	public ResponseEntity<Response<TicketDto>> verify(@RequestBody Request<QrActionDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> ticketBusiness.verify(request, locale)));
	}

	@PostMapping("/consume")
	@Operation(summary = "Consume ticket", description = "Scans and marks a **SOLD** ticket as **CONSUMED** at the venue.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = ConsumeTicketRequest.class)))
	public ResponseEntity<Response<TicketDto>> consume(@RequestBody Request<ConsumeTicketDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> ticketBusiness.consume(request, locale)));
	}

	@PostMapping("/get")
	@Operation(summary = "Get ticket by code", description = "Returns ticket details for `ticketCode`.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = TicketActionRequest.class)))
	public ResponseEntity<Response<TicketDto>> getByCode(@RequestBody Request<TicketActionDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> ticketBusiness.getByCode(request, locale)));
	}

	@PostMapping("/my")
	@Operation(summary = "My tickets", description = "Lists tickets purchased by `codeClient`, newest first.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = CodeClientRequest.class)))
	public ResponseEntity<Response<TicketDto>> myTickets(@RequestBody Request<CodeClientDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> ticketBusiness.myTickets(request, locale)));
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
