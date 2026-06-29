package com.djogana.ticketing.api.entity;

import java.time.LocalDateTime;

import com.djogana.ticketing.api.contracts.TicketAuditAction;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "T_TICKET_AUDIT_LOG")
@Getter
@Setter
public class TTicketAuditLog {

	@Id
	@Column(name = "ID", length = 36)
	private String id;

	@Column(name = "TICKET_ID", length = 36, nullable = false)
	private String ticketId;

	@Enumerated(EnumType.STRING)
	@Column(name = "ACTION", length = 30, nullable = false)
	private TicketAuditAction action;

	@Column(name = "ACTOR_CODE_CLIENT", length = 50)
	private String actorCodeClient;

	@Column(name = "ACTOR_NAME", length = 200)
	private String actorName;

	@Column(name = "PLACE", length = 300)
	private String place;

	@Column(name = "METADATA_JSON", length = 2000)
	private String metadataJson;

	@Column(name = "OCCURRED_AT", nullable = false)
	private LocalDateTime occurredAt;
}
