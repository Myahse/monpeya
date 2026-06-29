package com.djogana.ticketing.api.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.djogana.ticketing.api.contracts.Response;

public final class ApiResponses {

	private ApiResponses() {
	}

	public static <T> ResponseEntity<Response<T>> of(Response<T> response) {
		HttpStatus status = response != null && response.isHasError() ? HttpStatus.BAD_REQUEST : HttpStatus.OK;
		return new ResponseEntity<>(response, status);
	}
}
