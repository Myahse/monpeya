package com.djogana.ticketing.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.djogana.ticketing.api.entity.TTicketAuditLog;

public interface TTicketAuditLogRepository extends JpaRepository<TTicketAuditLog, String> {

	List<TTicketAuditLog> findByTicketIdOrderByOccurredAtAsc(String ticketId);
}
