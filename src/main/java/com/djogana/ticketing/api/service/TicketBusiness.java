package com.djogana.ticketing.api.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.djogana.ticketing.api.contracts.EventStatus;
import com.djogana.ticketing.api.contracts.FunctionalError;
import com.djogana.ticketing.api.contracts.PaymentStatus;
import com.djogana.ticketing.api.contracts.Request;
import com.djogana.ticketing.api.contracts.Response;
import com.djogana.ticketing.api.contracts.TicketAuditAction;
import com.djogana.ticketing.api.contracts.TicketPurpose;
import com.djogana.ticketing.api.contracts.TicketStatus;
import com.djogana.ticketing.api.dto.BuyTicketDto;
import com.djogana.ticketing.api.dto.CodeClientDto;
import com.djogana.ticketing.api.dto.ConsumeTicketDto;
import com.djogana.ticketing.api.dto.CreatorDashboardResultDto;
import com.djogana.ticketing.api.dto.EventDto;
import com.djogana.ticketing.api.dto.GenerateTicketsDto;
import com.djogana.ticketing.api.dto.QrActionDto;
import com.djogana.ticketing.api.dto.TicketActionDto;
import com.djogana.ticketing.api.dto.TicketDto;
import com.djogana.ticketing.api.entity.TEvent;
import com.djogana.ticketing.api.entity.TOrder;
import com.djogana.ticketing.api.entity.TTicket;
import com.djogana.ticketing.api.integration.peya.PeyaClientInfo;
import com.djogana.ticketing.api.repository.TEventRepository;
import com.djogana.ticketing.api.repository.TOrderRepository;
import com.djogana.ticketing.api.repository.TTicketRepository;
import com.djogana.ticketing.api.service.qr.SecureQrValidationResult;
import com.djogana.ticketing.api.service.qr.SecureQrValidatorService;
import com.djogana.ticketing.api.service.TicketPaymentService.PaymentResult;

@Service
public class TicketBusiness {

	@Autowired
	private TEventRepository eventRepository;

	@Autowired
	private TTicketRepository ticketRepository;

	@Autowired
	private TOrderRepository orderRepository;

	@Autowired
	private TicketMapper ticketMapper;

	@Autowired
	private QrTicketService qrTicketService;

	@Autowired
	private SecureQrValidatorService secureQrValidatorService;

	@Autowired
	private TicketAuditService ticketAuditService;

	@Autowired
	private TicketPaymentService ticketPaymentService;

	@Autowired
	private ClientLookupService clientLookupService;

	@Autowired
	private FunctionalError functionalError;

	@Transactional
	public Response<TicketDto> generate(Request<GenerateTicketsDto> request, Locale locale) {
		Response<TicketDto> response = new Response<>();
		GenerateTicketsDto data = request != null ? request.getData() : null;
		if (data == null || isBlank(data.getCodeClient()) || data.getQuantity() == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("codeClient, quantity", locale));
			return response;
		}
		int quantity = data.getQuantity();
		if (quantity <= 0) {
			response.setHasError(true);
			response.setStatus(functionalError.INVALID_DATA("quantity must be > 0", locale));
			return response;
		}

		PeyaClientInfo issuer = clientLookupService.requireClient(data, locale, response);
		if (response.isHasError()) {
			return response;
		}

		if (!isBlank(data.getEventCode())) {
			return generateForEvent(data, quantity, issuer, locale, response);
		}
		return generateStandalone(data, quantity, issuer, locale, response);
	}

	@Transactional(readOnly = true)
	public Response<TicketDto> getByCode(Request<TicketActionDto> request, Locale locale) {
		Response<TicketDto> response = new Response<>();
		if (request == null || request.getData() == null || isBlank(request.getData().getTicketCode())) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("ticketCode", locale));
			return response;
		}
		TTicket ticket = ticketRepository.findByTicketCode(request.getData().getTicketCode().trim()).orElse(null);
		if (ticket == null) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_FOUND("ticket ticketCode=" + request.getData().getTicketCode(), locale));
			return response;
		}
		response.setHasError(false);
		response.setItem(toTicketDtoWithOrderRef(ticket));
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional
	public Response<TicketDto> buy(Request<BuyTicketDto> request, Locale locale) {
		Response<TicketDto> response = new Response<>();
		BuyTicketDto data = request != null ? request.getData() : null;
		if (data == null || isBlank(data.getTicketCode()) || isBlank(data.getCodeClient())) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("ticketCode, codeClient", locale));
			return response;
		}

		PeyaClientInfo buyer = clientLookupService.requireClient(data, locale, response);
		if (response.isHasError()) {
			return response;
		}

		TTicket ticket = ticketRepository.findByTicketCode(data.getTicketCode().trim()).orElse(null);
		if (ticket == null) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_FOUND("ticket ticketCode=" + data.getTicketCode(), locale));
			return response;
		}
		if (ticket.getStatus() != TicketStatus.FOR_SALE) {
			response.setHasError(true);
			response.setStatus(functionalError.DISALLOWED_OPERATION("ticket is not available for sale", locale));
			return response;
		}

		TEvent event = null;
		if (ticket.getPurpose() == TicketPurpose.EVENT) {
			if (ticket.getEventId() == null) {
				response.setHasError(true);
				response.setStatus(functionalError.INVALID_DATA("event ticket missing event link", locale));
				return response;
			}
			event = eventRepository.findById(ticket.getEventId()).orElse(null);
			if (event == null || event.getStatus() != EventStatus.PUBLISHED) {
				response.setHasError(true);
				response.setStatus(functionalError.DISALLOWED_OPERATION("event is not published", locale));
				return response;
			}
		}

		PaymentResult payment = ticketPaymentService.processWalletDebit(buyer.getCodeClient(), ticket.getPrice(), locale);
		if (!payment.isSuccess()) {
			response.setHasError(true);
			response.setStatus(functionalError.PAY_FAIL(payment.getErrorMessage(), locale));
			return response;
		}

		String buyerName = clientLookupService.clientDisplayName(buyer);
		LocalDateTime now = LocalDateTime.now();

		TOrder order = new TOrder();
		order.setId(UUID.randomUUID().toString());
		order.setOrderRef("ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
		order.setEventId(event != null ? event.getId() : null);
		order.setTicketId(ticket.getId());
		clientLookupService.applyBuyerSnapshot(order, buyer);
		order.setAmount(ticket.getPrice());
		order.setPaymentStatus(PaymentStatus.PAID);
		order.setPaymentMethod(isBlank(data.getPaymentMethod()) ? "PEYA_WALLET" : data.getPaymentMethod());
		order.setPaymentReference(payment.getPaymentReference());
		order.setReferOp(payment.getReferOp());
		order.setCreatedAt(now);
		order.setPaidAt(now);
		orderRepository.save(order);

		ticket.setOrderId(order.getId());
		clientLookupService.applyBuyerSnapshot(ticket, buyer);
		ticket.setPurchasedAt(now);
		ticket.setAmountPaid(ticket.getPrice());
		ticket.setPaymentReference(payment.getPaymentReference());
		ticket.setReferOp(payment.getReferOp());
		ticket.setStatus(TicketStatus.SOLD);
		ticketRepository.save(ticket);

		if (event != null) {
			event.setTicketsSold(event.getTicketsSold() + 1);
			eventRepository.save(event);
		}

		ticketAuditService.log(ticket.getId(), TicketAuditAction.SOLD, buyer.getCodeClient(), buyerName,
				null, "{\"orderRef\":\"" + order.getOrderRef() + "\"}");

		TicketDto dto = ticketMapper.toTicketDto(ticket);
		dto.setOrderRef(order.getOrderRef());
		response.setHasError(false);
		response.setItem(dto);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional(readOnly = true)
	public Response<TicketDto> verify(Request<QrActionDto> request, Locale locale) {
		Response<TicketDto> response = new Response<>();
		QrActionDto data = request != null ? request.getData() : null;
		if (data == null || isBlank(data.getQrPayload())) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("qrPayload", locale));
			return response;
		}
		TTicket ticket = resolveTicketFromQr(data.getQrPayload(), locale, response);
		if (response.isHasError()) {
			return response;
		}

		response.setHasError(false);
		response.setItem(toTicketDtoWithOrderRef(ticket));
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional
	public Response<TicketDto> consume(Request<ConsumeTicketDto> request, Locale locale) {
		Response<TicketDto> response = new Response<>();
		ConsumeTicketDto data = request != null ? request.getData() : null;
		if (data == null || isBlank(data.getQrPayload()) || isBlank(data.getScannerCodeClient())) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("qrPayload, scannerCodeClient", locale));
			return response;
		}

		PeyaClientInfo scanner = clientLookupService.requireClient(data, locale, response);
		if (response.isHasError()) {
			return response;
		}
		String scannerName = clientLookupService.clientDisplayName(scanner);

		TTicket ticket = resolveTicketFromQr(data.getQrPayload(), locale, response);
		if (response.isHasError()) {
			return response;
		}
		if (ticket.getStatus() == TicketStatus.CONSUMED) {
			response.setHasError(true);
			response.setStatus(functionalError.DISALLOWED_OPERATION("ticket already consumed", locale));
			return response;
		}
		if (ticket.getStatus() != TicketStatus.SOLD) {
			response.setHasError(true);
			response.setStatus(functionalError.DISALLOWED_OPERATION("ticket is not sold", locale));
			return response;
		}

		LocalDateTime now = LocalDateTime.now();
		int updated = ticketRepository.consumeIfSold(ticket.getTicketCode(), now, data.getConsumedPlace(),
				scanner.getCodeClient(), scannerName, data.getScannerDeviceId());
		if (updated != 1) {
			response.setHasError(true);
			response.setStatus(functionalError.DISALLOWED_OPERATION("ticket could not be consumed", locale));
			return response;
		}

		if (ticket.getEventId() != null) {
			eventRepository.incrementConsumed(ticket.getEventId());
		}
		ticket = ticketRepository.findByTicketCode(ticket.getTicketCode()).orElse(ticket);

		ticketAuditService.log(ticket.getId(), TicketAuditAction.CONSUMED, scanner.getCodeClient(),
				scannerName, data.getConsumedPlace(), null);

		response.setHasError(false);
		response.setItem(toTicketDtoWithOrderRef(ticket));
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional(readOnly = true)
	public Response<TicketDto> myTickets(Request<CodeClientDto> request, Locale locale) {
		Response<TicketDto> response = new Response<>();
		PeyaClientInfo buyer = clientLookupService.requireClient(
				request != null ? request.getData() : null, locale, response);
		if (response.isHasError()) {
			return response;
		}
		List<TicketDto> items = ticketRepository
				.findByBuyerCodeClientOrderByPurchasedAtDesc(buyer.getCodeClient())
				.stream().map(this::toTicketDtoWithOrderRef).collect(Collectors.toList());
		response.setHasError(false);
		response.setItems(items);
		response.setCount((long) items.size());
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional(readOnly = true)
	public Response<TicketDto> creatorTickets(Request<CodeClientDto> request, Locale locale) {
		Response<TicketDto> response = new Response<>();
		PeyaClientInfo creator = clientLookupService.requireClient(
				request != null ? request.getData() : null, locale, response);
		if (response.isHasError()) {
			return response;
		}
		List<TEvent> events = eventRepository
				.findByCreatorCodeClientOrderByCreatedAtDesc(creator.getCodeClient());
		List<TicketDto> items = new ArrayList<>();
		for (TEvent event : events) {
			items.addAll(ticketRepository.findByEventIdOrderByGeneratedAtDesc(event.getId()).stream()
					.map(this::toTicketDtoWithOrderRef).toList());
		}
		items.addAll(ticketRepository
				.findByBuiltByCodeClientAndPurposeNotOrderByGeneratedAtDesc(creator.getCodeClient(), TicketPurpose.EVENT)
				.stream().map(this::toTicketDtoWithOrderRef).toList());
		response.setHasError(false);
		response.setItems(items);
		response.setCount((long) items.size());
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	@Transactional(readOnly = true)
	public Response<CreatorDashboardResultDto> creatorDashboard(Request<CodeClientDto> request, Locale locale) {
		Response<CreatorDashboardResultDto> response = new Response<>();
		PeyaClientInfo creator = clientLookupService.requireClient(
				request != null ? request.getData() : null, locale, response);
		if (response.isHasError()) {
			return response;
		}
		List<EventDto> events = eventRepository
				.findByCreatorCodeClientOrderByCreatedAtDesc(creator.getCodeClient())
				.stream().map(ticketMapper::toEventDto).collect(Collectors.toList());

		CreatorDashboardResultDto dashboard = new CreatorDashboardResultDto();
		dashboard.setEvents(events);
		dashboard.setTotalTicketsGenerated(events.stream().mapToLong(e -> e.getTicketsGenerated() != null ? e.getTicketsGenerated() : 0).sum());
		dashboard.setTotalTicketsSold(events.stream().mapToLong(e -> e.getTicketsSold() != null ? e.getTicketsSold() : 0).sum());
		dashboard.setTotalTicketsConsumed(events.stream().mapToLong(e -> e.getTicketsConsumed() != null ? e.getTicketsConsumed() : 0).sum());

		response.setHasError(false);
		response.setItem(dashboard);
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	private Response<TicketDto> generateForEvent(GenerateTicketsDto data, int quantity, PeyaClientInfo issuer,
			Locale locale, Response<TicketDto> response) {
		TEvent event = clientLookupService.requireOwnedEventByCode(data.getEventCode(), issuer, locale, response);
		if (response.isHasError()) {
			return response;
		}
		if (event.getStatus() == EventStatus.CANCELLED || event.getStatus() == EventStatus.CLOSED) {
			response.setHasError(true);
			response.setStatus(functionalError.DISALLOWED_OPERATION("event is not open for ticket generation", locale));
			return response;
		}
		if (event.getTicketsGenerated() + quantity > event.getMaxTickets()) {
			response.setHasError(true);
			response.setStatus(functionalError.CUSTOM("max ticket limit reached for this event", locale));
			return response;
		}

		TicketStatus initialStatus = event.getStatus() == EventStatus.PUBLISHED
				? TicketStatus.FOR_SALE
				: TicketStatus.GENERATED;

		String ticketType = isBlank(data.getTicketType()) ? "STANDARD" : data.getTicketType();
		String eventPlace = buildEventPlace(event);
		List<TicketDto> created = new ArrayList<>();

		for (int i = 0; i < quantity; i++) {
			created.add(saveNewTicket(TicketPurpose.EVENT, event.getEventCode(), event.getId(),
					event.getName(), eventPlace, event.getStartAt(), event.getTicketPrice(),
					ticketType, issuer, initialStatus, eventPlace));
		}

		event.setTicketsGenerated(event.getTicketsGenerated() + quantity);
		eventRepository.save(event);

		response.setHasError(false);
		response.setItems(created);
		response.setCount((long) created.size());
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	private Response<TicketDto> generateStandalone(GenerateTicketsDto data, int quantity, PeyaClientInfo issuer,
			Locale locale, Response<TicketDto> response) {
		TicketPurpose purpose = data.getPurpose() != null ? data.getPurpose() : TicketPurpose.GENERIC;
		if (purpose == TicketPurpose.EVENT) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("eventCode (required for EVENT purpose)", locale));
			return response;
		}
		if (isBlank(data.getTitle()) || data.getValidFrom() == null || data.getPrice() == null) {
			response.setHasError(true);
			response.setStatus(functionalError.FIELD_EMPTY("title, validFrom, price (standalone tickets)", locale));
			return response;
		}
		if (data.getPrice().signum() < 0) {
			response.setHasError(true);
			response.setStatus(functionalError.INVALID_DATA("price must be >= 0", locale));
			return response;
		}

		String ticketType = isBlank(data.getTicketType()) ? purpose.name() : data.getTicketType();
		List<TicketDto> created = new ArrayList<>();
		for (int i = 0; i < quantity; i++) {
			created.add(saveNewTicket(purpose, null, null, data.getTitle(), data.getPlace(),
					data.getValidFrom(), data.getPrice(), ticketType, issuer, TicketStatus.FOR_SALE, data.getPlace()));
		}

		response.setHasError(false);
		response.setItems(created);
		response.setCount((long) created.size());
		response.setStatus(functionalError.SUCCESS("", locale));
		return response;
	}

	private TicketDto saveNewTicket(TicketPurpose purpose, String eventCode, String eventId,
			String title, String place, LocalDateTime validFrom, java.math.BigDecimal price,
			String ticketType, PeyaClientInfo issuer, TicketStatus initialStatus, String auditPlace) {
		TTicket ticket = new TTicket();
		String ticketId = UUID.randomUUID().toString();
		String ticketCode = "TKT-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
		ticket.setId(ticketId);
		ticket.setTicketCode(ticketCode);
		ticket.setPurpose(purpose);
		ticket.setEventId(eventId);
		ticket.setEventCode(eventCode);
		ticket.setEventName(title);
		ticket.setEventPlace(place);
		ticket.setEventStartAt(validFrom);
		ticket.setTicketType(ticketType);
		ticket.setPrice(price);
		ticket.setBuiltByCodeClient(issuer.getCodeClient());
		ticket.setBuiltByName(clientLookupService.clientDisplayName(issuer));
		ticket.setGeneratedAt(LocalDateTime.now());
		ticket.setStatus(initialStatus);
		ticket.setQrPayload(TicketQrConstants.CLIENT_GENERATED);
		ticketRepository.save(ticket);
		ticketAuditService.log(ticketId, TicketAuditAction.GENERATED, issuer.getCodeClient(),
				clientLookupService.clientDisplayName(issuer), auditPlace, null);
		return ticketMapper.toTicketDto(ticket);
	}

	private TTicket resolveTicketFromQr(String qrPayload, Locale locale, Response<TicketDto> response) {
		String ticketCode = null;

		if (qrPayload.startsWith("TKT|")) {
			if (!qrTicketService.isValid(qrPayload)) {
				response.setHasError(true);
				response.setStatus(functionalError.INVALID_DATA("invalid legacy QR signature", locale));
				return null;
			}
			ticketCode = qrTicketService.extractTicketCode(qrPayload);
		} else {
			SecureQrValidationResult validation = secureQrValidatorService.validate(qrPayload);
			if (!validation.isValid()) {
				response.setHasError(true);
				String msg = validation.isExpired() ? "QR code expired" : validation.getErrorMessage();
				response.setStatus(functionalError.INVALID_DATA(msg != null ? msg : "invalid QR", locale));
				return null;
			}
			ticketCode = validation.getTicketCode();
		}

		if (ticketCode == null || ticketCode.isBlank()) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_FOUND("ticket", locale));
			return null;
		}

		TTicket ticket = ticketRepository.findByTicketCode(ticketCode.trim()).orElse(null);
		if (ticket == null) {
			response.setHasError(true);
			response.setStatus(functionalError.DATA_NOT_FOUND("ticket ticketCode=" + ticketCode, locale));
		}
		return ticket;
	}

	private TicketDto toTicketDtoWithOrderRef(TTicket ticket) {
		TicketDto dto = ticketMapper.toTicketDto(ticket);
		if (ticket.getOrderId() != null) {
			orderRepository.findById(ticket.getOrderId())
					.ifPresent(order -> dto.setOrderRef(order.getOrderRef()));
		}
		return dto;
	}

	private static String buildEventPlace(TEvent event) {
		StringBuilder sb = new StringBuilder();
		if (!isBlank(event.getVenueName())) {
			sb.append(event.getVenueName());
		}
		if (!isBlank(event.getCity())) {
			if (sb.length() > 0) {
				sb.append(", ");
			}
			sb.append(event.getCity());
		}
		if (!isBlank(event.getCountry())) {
			if (sb.length() > 0) {
				sb.append(", ");
			}
			sb.append(event.getCountry());
		}
		return sb.toString();
	}

	private static boolean isBlank(String value) {
		return value == null || value.isBlank();
	}
}
