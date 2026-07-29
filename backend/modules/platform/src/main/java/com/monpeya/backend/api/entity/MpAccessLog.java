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
@Table(name = "MP_ACCESS_LOG")
public class MpAccessLog {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_access_log_seq")
	@SequenceGenerator(name = "mp_access_log_seq", sequenceName = "MP_ACCESS_LOG_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "USER_ID")
	private MpUser user;

	@Column(name = "PHONE", length = 20)
	private String phone;

	@Column(name = "MODULE_CODE", length = 50)
	private String moduleCode;

	@Column(name = "ACTION_CODE", length = 80)
	private String actionCode;

	@Column(name = "ACCESS_LEVEL", length = 20)
	private String accessLevel;

	@Column(name = "RESULT", nullable = false, length = 20)
	private String result;

	@Column(name = "REASON", length = 200)
	private String reason;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();
}
