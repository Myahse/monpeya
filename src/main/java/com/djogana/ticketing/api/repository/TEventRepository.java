package com.djogana.ticketing.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.djogana.ticketing.api.contracts.EventStatus;
import com.djogana.ticketing.api.entity.TEvent;

public interface TEventRepository extends JpaRepository<TEvent, String> {

	Optional<TEvent> findByEventCode(String eventCode);

	Optional<TEvent> findByEventCodeAndCreatorCodeClient(String eventCode, String creatorCodeClient);

	List<TEvent> findByStatusOrderByStartAtAsc(EventStatus status);

	List<TEvent> findByCreatorCodeClientOrderByCreatedAtDesc(String creatorCodeClient);

	@Modifying
	@Query("UPDATE TEvent e SET e.ticketsGenerated = e.ticketsGenerated + :qty WHERE e.id = :eventId AND e.ticketsGenerated + :qty <= e.maxTickets")
	int incrementGeneratedIfCapacity(@Param("eventId") String eventId, @Param("qty") int qty);

	@Modifying
	@Query("UPDATE TEvent e SET e.ticketsSold = e.ticketsSold + 1 WHERE e.id = :eventId")
	int incrementSold(@Param("eventId") String eventId);

	@Modifying
	@Query("UPDATE TEvent e SET e.ticketsConsumed = e.ticketsConsumed + 1 WHERE e.id = :eventId")
	int incrementConsumed(@Param("eventId") String eventId);
}
