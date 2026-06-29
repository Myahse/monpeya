package com.djogana.ticketing.api.openapi;

import com.djogana.ticketing.api.dto.BuyTicketDto;
import com.djogana.ticketing.api.dto.CodeClientDto;
import com.djogana.ticketing.api.dto.ConsumeTicketDto;
import com.djogana.ticketing.api.dto.EventActionDto;
import com.djogana.ticketing.api.dto.EventCreateDto;
import com.djogana.ticketing.api.dto.GenerateTicketsDto;
import com.djogana.ticketing.api.dto.PingDto;
import com.djogana.ticketing.api.dto.QrActionDto;

import com.djogana.ticketing.api.dto.TicketActionDto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * Typed request envelopes for OpenAPI / Swagger UI (runtime still uses {@code Request<T>}).
 */
public final class ApiRequestSchemas {

	private ApiRequestSchemas() {
	}

	@Schema(name = "PingRequest")
	public static class PingRequest {
		@Schema(description = "Optional payload")
		public PingDto data;
	}

	@Schema(name = "CodeClientRequest")
	public static class CodeClientRequest {
		@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
		public CodeClientDto data;
	}

	@Schema(name = "EventCreateRequest")
	public static class EventCreateRequest {
		@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
		public EventCreateDto data;
	}

	@Schema(name = "EventActionRequest")
	public static class EventActionRequest {
		@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
		public EventActionDto data;
	}

	@Schema(name = "PublicEventsRequest")
	public static class PublicEventsRequest {
		@Schema(description = "Optional; body may be empty or { \"data\": {} }")
		public Object data;
	}

	@Schema(name = "GenerateTicketsRequest")
	public static class GenerateTicketsRequest {
		@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
		public GenerateTicketsDto data;
	}

	@Schema(name = "BuyTicketRequest")
	public static class BuyTicketRequest {
		@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
		public BuyTicketDto data;
	}

	@Schema(name = "QrActionRequest")
	public static class QrActionRequest {
		@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
		public QrActionDto data;
	}

	@Schema(name = "ConsumeTicketRequest")
	public static class ConsumeTicketRequest {
		@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
		public ConsumeTicketDto data;
	}

	@Schema(name = "TicketActionRequest")
	public static class TicketActionRequest {
		@Schema(requiredMode = Schema.RequiredMode.REQUIRED)
		public TicketActionDto data;
	}
}
