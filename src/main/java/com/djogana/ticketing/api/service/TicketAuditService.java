package com.djogana.ticketing.api.service;

import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.djogana.ticketing.api.contracts.TicketAuditAction;
import com.djogana.ticketing.api.entity.TTicketAuditLog;
import com.djogana.ticketing.api.repository.TTicketAuditLogRepository;

@Service
public class TicketAuditService {

	@Autowired
	private TTicketAuditLogRepository auditLogRepository;

	@Transactional(propagation = Propagation.REQUIRES_NEW)
	public void log(String ticketId, TicketAuditAction action, String actorCodeClient, String actorName,
			String place, String metadataJson) {
		TTicketAuditLog log = new TTicketAuditLog();
		log.setId(UUID.randomUUID().toString());
		log.setTicketId(ticketId);
		log.setAction(action);
		log.setActorCodeClient(actorCodeClient);
		log.setActorName(actorName);
		log.setPlace(place);
		log.setMetadataJson(metadataJson);
		log.setOccurredAt(LocalDateTime.now());
		auditLogRepository.save(log);
	}
}
