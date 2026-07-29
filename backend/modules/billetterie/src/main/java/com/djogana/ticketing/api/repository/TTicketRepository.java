package com.djogana.ticketing.api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.djogana.ticketing.api.contracts.TicketPurpose;
import com.djogana.ticketing.api.contracts.TicketStatus;
import com.djogana.ticketing.api.entity.TTicket;

public interface TTicketRepository extends JpaRepository<TTicket, String> {

	Optional<TTicket> findByTicketCode(String ticketCode);

	Optional<TTicket> findByQrPayload(String qrPayload);

	List<TTicket> findByEventIdOrderByGeneratedAtDesc(String eventId);

	List<TTicket> findByBuiltByCodeClientAndPurposeNotOrderByGeneratedAtDesc(
			String builtByCodeClient, TicketPurpose purpose);

	List<TTicket> findByBuyerCodeClientOrderByPurchasedAtDesc(String buyerCodeClient);

	List<TTicket> findByEventIdAndStatus(String eventId, TicketStatus status);

	long countByEventIdAndStatus(String eventId, TicketStatus status);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("UPDATE TTicket t SET t.status = :newStatus WHERE t.eventId = :eventId AND t.status = :oldStatus")
	int updateStatusByEvent(@Param("eventId") String eventId,
			@Param("oldStatus") TicketStatus oldStatus,
			@Param("newStatus") TicketStatus newStatus);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("UPDATE TTicket t SET t.status = com.djogana.ticketing.api.contracts.TicketStatus.CONSUMED, "
			+ "t.consumedAt = :consumedAt, t.consumedPlace = :place, t.consumedByCodeClient = :scannerCodeClient, "
			+ "t.consumedByName = :scannerName, t.scannerDeviceId = :deviceId "
			+ "WHERE t.ticketCode = :ticketCode AND t.status = com.djogana.ticketing.api.contracts.TicketStatus.SOLD")
	int consumeIfSold(@Param("ticketCode") String ticketCode,
			@Param("consumedAt") java.time.LocalDateTime consumedAt,
			@Param("place") String place,
			@Param("scannerCodeClient") String scannerCodeClient,
			@Param("scannerName") String scannerName,
			@Param("deviceId") String deviceId);
}
