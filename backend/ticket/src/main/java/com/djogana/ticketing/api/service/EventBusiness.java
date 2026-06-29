package com.djogana.ticketing.api.service;

import java.time.LocalDateTime;
import java.time.Year;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.djogana.ticketing.api.contracts.EventStatus;
import com.djogana.ticketing.api.contracts.FunctionalError;
import com.djogana.ticketing.api.contracts.Request;
import com.djogana.ticketing.api.contracts.Response;
import com.djogana.ticketing.api.contracts.TicketStatus;
import com.djogana.ticketing.api.dto.EventActionDto;
import com.djogana.ticketing.api.dto.EventCreateDto;
import com.djogana.ticketing.api.dto.EventDto;
import com.djogana.ticketing.api.entity.TEvent;
import com.djogana.ticketing.api.integration.peya.PeyaClientInfo;
import com.djogana.ticketing.api.repository.TEventRepository;
import com.djogana.ticketing.api.repository.TTicketRepository;

@Service
public class EventBusiness {

	@Autowired
	private TEventRepository eventRepository;

	@Autowired
	private TTicketRepository ticketRepository;

	@Autowired
	private TicketMapper ticketMapper;

	@Autowired
	private ClientLookupService clientLookupService;

	@Autowired
	private FunctionalError functionalError;

	@Transactional
	public Response<EventDto> create(Request<EventCreateDto> request, Locale locale) {
		Response<EventDto> response = new Response<>();
		EventCreateDto data = request != null ? request.getData() : null;
		if (data == null || isBlank(data.getCodeClient()) || isBlank(data.getName()) || isBlank(data.getCategory())
				|| data.getStartAt() == null || data.getEndAt() == null
				|| data.getTicketPrice() == null || data.getMaxTickets() == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("codeClient, name, category, dates, price, maxTickets", locale));
			return response;
		}
		if (data.getMaxTickets() <= 0) {
			response.setHasError(true);
			response.setStatus(functionalError.INVALID_DATA("maxTickets must be > 0", locale));
			return response;
		}

		PeyaClientInfo creator = clientLookupService.requireClient(data, locale, response);
		if (response.isHasError()) {
			return response;
		}

		TEvent event = new TEvent();
		event.setId(UUID.randomUUID().toString());
		event.setEventCode("EVT-" + Year.now().getValue() + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
		clientLookupService.applyCreatorSnapshot(event, creator);
		event.setName(data.getName());
		event.setCategory(data.getCategory());
		event.setVenueName(data.getVenueName());
		event.setAddress(data.getAddress());
		event.setCity(data.getCity());
		event.setCountry(data.getCountry());
		event.setLatitude(data.getLatitude());
		event.setLongitude(data.getLongitude());
		event.setStartAt(data.getStartAt());
		event.setEndAt(data.getEndAt());
		event.setTicketPrice(data.getTicketPrice());
		event.setMaxTickets(data.getMaxTickets());
		event.setTicketsGenerated(0);
		event.setTicketsSold(0);
		event.setTicketsConsumed(0);
		event.setStatus(EventStatus.DRAFT);
		event.setCreatedAt(LocalDateTime.now());

		eventRepository.save(event);
		response.setHasError(false);
		response.setItem(ticketMapper.toEventDto(event));
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional
	public Response<EventDto> publish(Request<EventActionDto> request, Locale locale) {
		Response<EventDto> response = new Response<>();
		EventActionDto data = request != null ? request.getData() : null;
		if (data == null || isBlank(data.getEventCode()) || isBlank(data.getCodeClient())) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("eventCode, codeClient", locale));
			return response;
		}

		PeyaClientInfo creator = clientLookupService.requireClient(data, locale, response);
		if (response.isHasError()) {
			return response;
		}

		TEvent event = clientLookupService.requireOwnedEventByCode(data.getEventCode(), creator, locale, response);
		if (response.isHasError()) {
			return response;
		}
		if (event.getStatus() != EventStatus.DRAFT) {
			response.setHasError(true);
			response.setStatus(functionalError.DISALLOWED_OPERATION("only DRAFT events can be published", locale));
			return response;
		}

		event.setStatus(EventStatus.PUBLISHED);
		event.setPublishedAt(LocalDateTime.now());
		eventRepository.save(event);
		ticketRepository.updateStatusByEvent(event.getId(), TicketStatus.GENERATED, TicketStatus.FOR_SALE);

		response.setHasError(false);
		response.setItem(ticketMapper.toEventDto(event));
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional(readOnly = true)
	public Response<EventDto> listPublic(Locale locale) {
		Response<EventDto> response = new Response<>();
		List<EventDto> items = eventRepository.findByStatusOrderByStartAtAsc(EventStatus.PUBLISHED).stream()
				.map(ticketMapper::toEventDto)
				.collect(Collectors.toList());
		response.setHasError(false);
		response.setItems(items);
		response.setCount((long) items.size());
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional(readOnly = true)
	public Response<EventDto> getByCode(Request<EventActionDto> request, Locale locale) {
		Response<EventDto> response = new Response<>();
		if (request == null || request.getData() == null || isBlank(request.getData().getEventCode())) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("eventCode", locale));
			return response;
		}
		TEvent event = clientLookupService.requireEventByCode(request.getData().getEventCode(), locale, response);
		if (response.isHasError()) {
			return response;
		}
		response.setHasError(false);
		response.setItem(ticketMapper.toEventDto(event));
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	private static boolean isBlank(String value) {
		return value == null || value.isBlank();
	}
}
