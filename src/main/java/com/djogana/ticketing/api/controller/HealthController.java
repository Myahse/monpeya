package com.djogana.ticketing.api.controller;

import java.util.Locale;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.djogana.ticketing.api.contracts.Request;
import com.djogana.ticketing.api.contracts.Response;
import com.djogana.ticketing.api.dto.PingDto;
import com.djogana.ticketing.api.openapi.ApiRequestSchemas.PingRequest;
import com.djogana.ticketing.api.service.HealthService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/v1")
@Tag(name = "Health", description = "Service health checks")
public class HealthController {

	@Autowired
	private HealthService healthService;

	@PostMapping("/ping")
	@Operation(summary = "Health ping", description = "Verifies the API and database connectivity.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(
			required = false,
			content = @Content(schema = @Schema(implementation = PingRequest.class)))
	public ResponseEntity<Response<PingDto>> ping(
			@RequestBody(required = false) Request<PingDto> request,
			Locale locale) {
		Response<PingDto> response = healthService.ping(
				request != null ? request : new Request<>(), locale);
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}
}
