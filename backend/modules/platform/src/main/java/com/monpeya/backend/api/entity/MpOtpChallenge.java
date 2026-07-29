package com.monpeya.backend.api.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "MP_OTP_CHALLENGE")
public class MpOtpChallenge {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_otp_seq")
	@SequenceGenerator(name = "mp_otp_seq", sequenceName = "MP_OTP_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@Column(name = "PHONE", nullable = false, length = 20)
	private String phone;

	@Column(name = "PURPOSE", nullable = false, length = 40)
	private String purpose;

	@Column(name = "STATUS", nullable = false, length = 20)
	private String status;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();

	@Column(name = "VERIFIED_AT")
	private LocalDateTime verifiedAt;
}
