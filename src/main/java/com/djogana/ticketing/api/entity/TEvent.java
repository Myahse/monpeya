package com.djogana.ticketing.api.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.djogana.ticketing.api.contracts.EventStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "T_EVENT")
@Getter
@Setter
public class TEvent {

	@Id
	@Column(name = "ID", length = 36)
	private String id;

	@Column(name = "EVENT_CODE", length = 50, nullable = false, unique = true)
	private String eventCode;

	@Column(name = "CREATOR_CODE_CLIENT", length = 50, nullable = false)
	private String creatorCodeClient;

	@Column(name = "CREATOR_NAME", length = 200, nullable = false)
	private String creatorName;

	@Column(name = "CREATOR_PHONE", length = 30)
	private String creatorPhone;

	@Column(name = "NAME", length = 300, nullable = false)
	private String name;

	@Column(name = "CATEGORY", length = 50, nullable = false)
	private String category;

	@Column(name = "VENUE_NAME", length = 300)
	private String venueName;

	@Column(name = "ADDRESS", length = 500)
	private String address;

	@Column(name = "CITY", length = 100)
	private String city;

	@Column(name = "COUNTRY", length = 100)
	private String country;

	@Column(name = "LATITUDE", precision = 10, scale = 7)
	private BigDecimal latitude;

	@Column(name = "LONGITUDE", precision = 10, scale = 7)
	private BigDecimal longitude;

	@Column(name = "START_AT", nullable = false)
	private LocalDateTime startAt;

	@Column(name = "END_AT", nullable = false)
	private LocalDateTime endAt;

	@Column(name = "TICKET_PRICE", nullable = false)
	private BigDecimal ticketPrice;

	@Column(name = "MAX_TICKETS", nullable = false)
	private Integer maxTickets;

	@Column(name = "TICKETS_GENERATED", nullable = false)
	private Integer ticketsGenerated = 0;

	@Column(name = "TICKETS_SOLD", nullable = false)
	private Integer ticketsSold = 0;

	@Column(name = "TICKETS_CONSUMED", nullable = false)
	private Integer ticketsConsumed = 0;

	@Enumerated(EnumType.STRING)
	@Column(name = "STATUS", length = 20, nullable = false)
	private EventStatus status;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt;

	@Column(name = "PUBLISHED_AT")
	private LocalDateTime publishedAt;
}
