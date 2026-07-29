package com.monpeya.backend.api.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "MP_DEVICE")
public class MpDevice {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_device_seq")
	@SequenceGenerator(name = "mp_device_seq", sequenceName = "MP_DEVICE_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "USER_ID", nullable = false)
	private MpUser user;

	@Column(name = "IMEI", length = 100)
	private String imei;

	@Column(name = "MODELE", length = 200)
	private String modele;

	@Column(name = "PLATFORM", length = 50)
	private String platform;

	@Column(name = "LAST_SEEN_AT")
	private LocalDateTime lastSeenAt;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();
}
