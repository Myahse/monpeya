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
@Table(name = "MP_SESSION")
public class MpSession {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_session_seq")
	@SequenceGenerator(name = "mp_session_seq", sequenceName = "MP_SESSION_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "USER_ID", nullable = false)
	private MpUser user;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "DEVICE_ID")
	private MpDevice device;

	@Column(name = "ACCESS_TOKEN", nullable = false, length = 64, unique = true)
	private String accessToken;

	@Column(name = "REFRESH_TOKEN", nullable = false, length = 64, unique = true)
	private String refreshToken;

	@Column(name = "PEYA_ACCESS_TOKEN", length = 4000)
	private String peyaAccessToken;

	@Column(name = "EXPIRES_AT", nullable = false)
	private LocalDateTime expiresAt;

	@Column(name = "REFRESH_EXPIRES_AT", nullable = false)
	private LocalDateTime refreshExpiresAt;

	@Column(name = "REVOKED", nullable = false)
	private Boolean revoked = false;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();
}
