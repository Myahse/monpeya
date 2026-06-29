package com.djogana.ticketing.api.service;

import org.springframework.stereotype.Component;

import com.djogana.ticketing.api.dto.EventDto;
import com.djogana.ticketing.api.dto.TicketDto;
import com.djogana.ticketing.api.entity.TEvent;
import com.djogana.ticketing.api.entity.TTicket;

@Component
public class TicketMapper {

	public EventDto toEventDto(TEvent entity) {
		EventDto dto = new EventDto();
		dto.setEventCode(entity.getEventCode());
		dto.setCodeClient(entity.getCreatorCodeClient());
		dto.setCreatorName(entity.getCreatorName());
		dto.setCreatorPhone(entity.getCreatorPhone());
		dto.setName(entity.getName());
		dto.setCategory(entity.getCategory());
		dto.setVenueName(entity.getVenueName());
		dto.setAddress(entity.getAddress());
		dto.setCity(entity.getCity());
		dto.setCountry(entity.getCountry());
		dto.setLatitude(entity.getLatitude());
		dto.setLongitude(entity.getLongitude());
		dto.setStartAt(entity.getStartAt());
		dto.setEndAt(entity.getEndAt());
		dto.setTicketPrice(entity.getTicketPrice());
		dto.setMaxTickets(entity.getMaxTickets());
		dto.setTicketsGenerated(entity.getTicketsGenerated());
		dto.setTicketsSold(entity.getTicketsSold());
		dto.setTicketsConsumed(entity.getTicketsConsumed());
		dto.setStatus(entity.getStatus());
		dto.setCreatedAt(entity.getCreatedAt());
		dto.setPublishedAt(entity.getPublishedAt());
		return dto;
	}

	public TicketDto toTicketDto(TTicket entity) {
		TicketDto dto = new TicketDto();
		dto.setTicketCode(entity.getTicketCode());
		if (!TicketQrConstants.CLIENT_GENERATED.equals(entity.getQrPayload())) {
			dto.setQrPayload(entity.getQrPayload());
		}
		dto.setPurpose(entity.getPurpose());
		dto.setEventCode(entity.getEventCode());
		dto.setTitle(entity.getEventName());
		dto.setPlace(entity.getEventPlace());
		dto.setValidFrom(entity.getEventStartAt());
		dto.setTicketType(entity.getTicketType());
		dto.setPrice(entity.getPrice());
		dto.setBuiltByCodeClient(entity.getBuiltByCodeClient());
		dto.setBuiltByName(entity.getBuiltByName());
		dto.setGeneratedAt(entity.getGeneratedAt());
		dto.setBuyerCodeClient(entity.getBuyerCodeClient());
		dto.setBuyerName(entity.getBuyerName());
		dto.setBuyerPhone(entity.getBuyerPhone());
		dto.setPurchasedAt(entity.getPurchasedAt());
		dto.setAmountPaid(entity.getAmountPaid());
		dto.setPaymentReference(entity.getPaymentReference());
		dto.setReferOp(entity.getReferOp());
		dto.setConsumedAt(entity.getConsumedAt());
		dto.setConsumedPlace(entity.getConsumedPlace());
		dto.setConsumedByCodeClient(entity.getConsumedByCodeClient());
		dto.setConsumedByName(entity.getConsumedByName());
		dto.setScannerDeviceId(entity.getScannerDeviceId());
		dto.setStatus(entity.getStatus());
		return dto;
	}

	public void setOrderRef(TicketDto dto, String orderRef) {
		dto.setOrderRef(orderRef);
	}
}
