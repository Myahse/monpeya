package com.djogana.ticketing.api.service;

import java.util.Locale;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.djogana.ticketing.api.contracts.FunctionalError;
import com.djogana.ticketing.api.contracts.Request;
import com.djogana.ticketing.api.contracts.Response;
import com.djogana.ticketing.api.dto.CodeClientDto;
import com.djogana.ticketing.api.dto.WClientsDto;
import com.djogana.ticketing.api.integration.peya.PeyaClientInfo;

@Service
public class ClientBusiness {

	@Autowired
	private ClientLookupService clientLookupService;

	@Autowired
	private FunctionalError functionalError;

	@Transactional(readOnly = true)
	public Response<WClientsDto> getClient(Request<CodeClientDto> request, Locale locale) {
		Response<WClientsDto> response = new Response<>();
		PeyaClientInfo client = clientLookupService.requireClient(
				request != null ? request.getData() : null, locale, response);
		if (response.isHasError()) {
			return response;
		}
		response.setHasError(false);
		response.setItem(toSummary(client));
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	private WClientsDto toSummary(PeyaClientInfo client) {
		WClientsDto dto = new WClientsDto();
		dto.setCodeClient(client.getCodeClient());
		dto.setNomClient(client.getNomClient());
		dto.setGsmPrincipale(client.getGsmPrincipale());
		dto.setEmail(client.getEmail());
		dto.setLogin(client.getLogin());
		dto.setCodeBanque(client.getCodeBanque());
		dto.setAccountId(client.getAccountId());
		dto.setNumerocomptecomplet(client.getNumerocomptecomplet());
		dto.setSoldeDispo(client.getSoldeDispo());
		return dto;
	}
}
