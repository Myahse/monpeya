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
import com.monpeya.backend.api.dto.AuthPhoneDto;
import com.monpeya.backend.api.dto.AuthSessionDto;
import com.monpeya.backend.api.dto.AuthUserDto;
import com.monpeya.backend.api.service.AuthBusiness;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/v1/auth")
@Tag(name = "Auth", description = "Monpeya super-app auth (PeyaPay verify + local session)")
public class AuthController {

	@Autowired
	private AuthBusiness authBusiness;

	@PostMapping("/lookup")
	@Operation(summary = "Lookup phone against PeyaPay and upsert local user")
	public ResponseEntity<Response<AuthSessionDto>> lookup(
			@RequestBody Request<AuthPhoneDto> request,
			Locale locale) {
		return wrap(authBusiness.lookup(request, locale));
	}

	@PostMapping("/otp/send")
	@Operation(summary = "Send OTP via PeyaPay for unknown numbers")
	public ResponseEntity<Response<AuthSessionDto>> sendOtp(
			@RequestBody Request<AuthPhoneDto> request,
			Locale locale) {
		return wrap(authBusiness.sendOtp(request, locale));
	}

	@PostMapping("/otp/verify")
	@Operation(summary = "Verify OTP via PeyaPay")
	public ResponseEntity<Response<AuthSessionDto>> verifyOtp(
			@RequestBody Request<AuthPhoneDto> request,
			Locale locale) {
		return wrap(authBusiness.verifyOtp(request, locale));
	}

	@PostMapping("/login")
	@Operation(summary = "Login with phone + PIN (PeyaPay verify, Monpeya session)")
	public ResponseEntity<Response<AuthSessionDto>> login(
			@RequestBody Request<AuthPhoneDto> request,
			Locale locale) {
		return wrap(authBusiness.login(request, locale));
	}

	@PostMapping("/refresh")
	@Operation(summary = "Refresh Monpeya access token")
	public ResponseEntity<Response<AuthSessionDto>> refresh(
			@RequestBody Request<AuthPhoneDto> request,
			Locale locale) {
		return wrap(authBusiness.refresh(request, locale));
	}

	@PostMapping("/logout")
	@Operation(summary = "Revoke Monpeya session")
	public ResponseEntity<Response<AuthSessionDto>> logout(
			@RequestBody Request<AuthPhoneDto> request,
			Locale locale) {
		return wrap(authBusiness.logout(request, locale));
	}

	@PostMapping("/me")
	@Operation(summary = "Current Monpeya user from access token")
	public ResponseEntity<Response<AuthUserDto>> me(
			@RequestBody Request<AuthPhoneDto> request,
			Locale locale) {
		Response<AuthUserDto> response = authBusiness.me(request, locale);
		HttpStatus status = response.isHasError() ? HttpStatus.UNAUTHORIZED : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}

	private static ResponseEntity<Response<AuthSessionDto>> wrap(Response<AuthSessionDto> response) {
		HttpStatus status = response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}
}
