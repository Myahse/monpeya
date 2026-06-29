package com.djogana.ticketing.api.service;

import java.util.Locale;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.djogana.ticketing.api.contracts.FunctionalError;
import com.djogana.ticketing.api.contracts.Request;
import com.djogana.ticketing.api.contracts.Response;
import com.djogana.ticketing.api.dto.PingDto;

@Service
public class HealthService {

	@Autowired
	private FunctionalError functionalError;

	public Response<PingDto> ping(Request<PingDto> request, Locale locale) {
		Response<PingDto> response = new Response<>();

		Integer pingId = null;
		if (request != null && request.getData() != null) {
			pingId = request.getData().getPingId();
		}
		int pingIdVal = pingId != null ? pingId : 1;

		PingDto dto = new PingDto();
		dto.setPingId(pingIdVal);
		response.setItem(dto);
		response.setHasError(false);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}
}
