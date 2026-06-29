package com.djogana.ticketing.api.service;

import java.util.Locale;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.djogana.ticketing.api.contracts.FunctionalError;
import com.djogana.ticketing.api.contracts.ResponseBase;
import com.djogana.ticketing.api.dto.CodeClientHolder;
import com.djogana.ticketing.api.entity.TEvent;
import com.djogana.ticketing.api.entity.TOrder;
import com.djogana.ticketing.api.entity.TTicket;
import com.djogana.ticketing.api.entity.WClients;
import com.djogana.ticketing.api.integration.peya.PeyaApiClient;
import com.djogana.ticketing.api.integration.peya.PeyaApiException;
import com.djogana.ticketing.api.integration.peya.PeyaClientInfo;
import com.djogana.ticketing.api.repository.TEventRepository;
import com.djogana.ticketing.api.repository.WClientsRepository;

/**
 * Resolves Peya users via HTTP API ({@code /authclient/token} + {@code /wClients/rechercheclient}).
 * Ticketing T_* tables store {@code *_CODE_CLIENT} only. Falls back to local {@code W_Clients} when
 * {@code peya.api.enabled=false} (unit tests).
 */
@Service
public class ClientLookupService {

	@Autowired
	private PeyaApiClient peyaApiClient;

	@Autowired
	private WClientsRepository wClientsRepository;

	@Autowired
	private TEventRepository eventRepository;

	@Autowired
	private FunctionalError functionalError;

	public PeyaClientInfo requireClient(CodeClientHolder holder, Locale locale, ResponseBase response) {
		if (holder == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("codeClient", locale));
			return null;
		}
		return requireClient(holder.getCodeClient(), locale, response);
	}

	public PeyaClientInfo requireClient(String codeClient, Locale locale, ResponseBase response) {
		String normalized = normalize(codeClient);
		if (normalized == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("codeClient", locale));
			return null;
		}
		try {
			PeyaClientInfo client = loadClient(normalized);
			if (client == null || client.getCodeClient() == null || client.getCodeClient().isBlank()) {
				response.setHasError(true);
				response.setStatus(functionalError.DATA_NOT_FOUND("Peya client codeClient=" + normalized, locale));
				return null;
			}
			return client;
		} catch (PeyaApiException e) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_FOUND(e.getMessage(), locale));
			return null;
		}
	}

	public Optional<PeyaClientInfo> findClient(String codeClient) {
		String normalized = normalize(codeClient);
		if (normalized == null) {
			return Optional.empty();
		}
		try {
			return Optional.ofNullable(loadClient(normalized));
		} catch (PeyaApiException e) {
			return Optional.empty();
		}
	}

	public TEvent requireOwnedEventByCode(String eventCode, PeyaClientInfo client, Locale locale, ResponseBase response) {
		if (client == null) {
			return null;
		}
		if (eventCode == null || eventCode.isBlank()) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("eventCode", locale));
			return null;
		}
		TEvent event = eventRepository.findByEventCodeAndCreatorCodeClient(eventCode.trim(), client.getCodeClient())
				.orElse(null);
		if (event == null) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_FOUND("event eventCode=" + eventCode.trim(), locale));
		}
		return event;
	}

	public TEvent requireEventByCode(String eventCode, Locale locale, ResponseBase response) {
		if (eventCode == null || eventCode.isBlank()) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("eventCode", locale));
			return null;
		}
		TEvent event = eventRepository.findByEventCode(eventCode.trim()).orElse(null);
		if (event == null) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_FOUND("event eventCode=" + eventCode.trim(), locale));
		}
		return event;
	}

	public void applyCreatorSnapshot(TEvent event, PeyaClientInfo client) {
		event.setCreatorCodeClient(client.getCodeClient());
		event.setCreatorName(clientDisplayName(client));
		event.setCreatorPhone(clientPhone(client));
	}

	public void applyBuyerSnapshot(TTicket ticket, PeyaClientInfo buyer) {
		ticket.setBuyerCodeClient(buyer.getCodeClient());
		ticket.setBuyerName(clientDisplayName(buyer));
		ticket.setBuyerPhone(clientPhone(buyer));
	}

	public void applyBuyerSnapshot(TOrder order, PeyaClientInfo buyer) {
		order.setBuyerCodeClient(buyer.getCodeClient());
		order.setBuyerName(clientDisplayName(buyer));
		order.setBuyerPhone(clientPhone(buyer));
		order.setCodeClient(buyer.getCodeClient());
	}

	public void applyScannerSnapshot(TTicket ticket, PeyaClientInfo scanner, String deviceId) {
		ticket.setConsumedByCodeClient(scanner.getCodeClient());
		ticket.setConsumedByName(clientDisplayName(scanner));
		ticket.setScannerDeviceId(deviceId);
	}

	public String clientDisplayName(PeyaClientInfo client) {
		if (client == null) {
			return null;
		}
		if (client.getNomClient() != null && !client.getNomClient().isBlank()) {
			return client.getNomClient().trim();
		}
		return client.getGsmPrincipale();
	}

	public String clientPhone(PeyaClientInfo client) {
		if (client == null) {
			return null;
		}
		return client.getGsmPrincipale() != null ? client.getGsmPrincipale() : client.getCodeClient();
	}

	public String normalize(String codeClient) {
		if (codeClient == null || codeClient.isBlank()) {
			return null;
		}
		return codeClient.trim();
	}

	private PeyaClientInfo loadClient(String codeClient) {
		if (peyaApiClient.isEnabled()) {
			return peyaApiClient.searchClient(codeClient);
		}
		WClients local = wClientsRepository.findByCodeClientOrNull(codeClient);
		if (local == null) {
			return null;
		}
		PeyaClientInfo info = new PeyaClientInfo();
		info.setCodeClient(local.getCodeClient());
		info.setNomClient(local.getNomClient());
		info.setGsmPrincipale(local.getGsmPrincipale());
		info.setEmail(local.getEmail());
		info.setLogin(local.getLogin());
		info.setCodeBanque(local.getCodeBanque());
		info.setAccountId(local.getAccountId());
		return info;
	}
}
