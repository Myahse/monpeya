package com.djogana.ticketing.api.contracts;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * What a ticket is used for. {@link #EVENT} tickets are linked to {@code T_EVENT};
 * other purposes are standalone (e.g. conductor / transport passes).
 */
@Schema(description = "Ticket use case: EVENT (linked to eventCode), TRANSPORT (conductor/bus), PASS, GENERIC")
public enum TicketPurpose {
	EVENT,
	TRANSPORT,
	PASS,
	GENERIC
}
