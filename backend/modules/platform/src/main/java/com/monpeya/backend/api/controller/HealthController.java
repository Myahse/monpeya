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
import com.monpeya.backend.api.dto.PingDto;
import com.monpeya.backend.api.service.HealthService;

@RestController
@RequestMapping("/v1")
public class HealthController {

	@Autowired
	private HealthService healthService;

	@PostMapping("/ping")
	public ResponseEntity<Response<PingDto>> ping(
			@RequestBody(required = false) Request<PingDto> request,
			Locale locale) {
		Response<PingDto> response = healthService.ping(
				request != null ? request : new Request<>(), locale);
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}
}
