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
import com.djogana.ticketing.api.dto.WClientsDto;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.CodeClientRequest;
import com.djogana.ticketing.api.service.ClientBusiness;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/v1/clients")
@Tag(name = "Clients", description = "Peya client lookup (read-only)")
public class ClientController {

	@Autowired
	private ClientBusiness clientBusiness;

	@Autowired
	private ExceptionUtils exceptionUtils;

	@PostMapping("/get")
	@Operation(summary = "Get client", description = "Resolves a Peya client by `codeClient` (HTTP API or local W_CLIENTS fallback).")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = true,
			content = @Content(schema = @Schema(implementation = CodeClientRequest.class)))
	public ResponseEntity<Response<WClientsDto>> getClient(@RequestBody Request<CodeClientDto> request, Locale locale) {
		return ApiResponses.of(run(locale, () -> clientBusiness.getClient(request, locale)));
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
