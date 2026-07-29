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
@Table(name = "MP_USER")
public class MpUser {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_user_seq")
	@SequenceGenerator(name = "mp_user_seq", sequenceName = "MP_USER_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@Column(name = "PHONE", nullable = false, length = 20, unique = true)
	private String phone;

	@Column(name = "CODE_CLIENT", length = 50)
	private String codeClient;

	@Column(name = "NOM_CLIENT", length = 200)
	private String nomClient;

	@Column(name = "EMAIL", length = 200)
	private String email;

	@Column(name = "ACCOUNT_ID", length = 100)
	private String accountId;

	@Column(name = "DISPLAY_NAME", length = 200)
	private String displayName;

	@Column(name = "FIRST_NAME", length = 100)
	private String firstName;

	@Column(name = "LAST_NAME", length = 100)
	private String lastName;

	@Column(name = "BIRTH_DATE")
	private java.time.LocalDate birthDate;

	@Column(name = "ID_NUMBER", length = 50)
	private String idNumber;

	@Column(name = "ADRESSE", length = 500)
	private String adresse;

	@Column(name = "PROFESSION", length = 200)
	private String profession;

	@Column(name = "LIEU_NAISSANCE", length = 200)
	private String lieuNaissance;

	@Column(name = "CODE_PAYS_RESIDENCE", length = 10)
	private String codePaysResidence;

	@Column(name = "LOGIN_CLIENT", length = 100)
	private String loginClient;

	@Column(name = "CODE_BANQUE", length = 20)
	private String codeBanque;

	@Column(name = "NUMERO_COMPTE_COMPLET", length = 100)
	private String numerocomptecomplet;

	@Column(name = "SOLDE_DISPO")
	private java.math.BigDecimal soldeDispo;

	@Column(name = "KYC_STATUS", nullable = false, length = 30)
	private String kycStatus = "NONE";

	@Column(name = "PEYA_STATUS", length = 40)
	private String peyaStatus;

	@Column(name = "IS_PEYA_CLIENT", nullable = false)
	private Boolean isPeyaClient = false;

	/**
	 * True when Peya {@code rechercheclient} shows a supplier account ({@code typcpt=S}).
	 */
	@Column(name = "IS_PEYAPAY_MERCHANT", nullable = false)
	private Boolean isPeyapayMerchant = false;

	/** Peya {@code deplafonner} — CLIENT subscribe debit requires this. */
	@Column(name = "IS_DEPLAFONNE", nullable = false)
	private Boolean isDeplafonne = false;

	@Column(name = "STATUS", nullable = false, length = 20)
	private String status = "ACTIVE";

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();

	@Column(name = "UPDATED_AT", nullable = false)
	private LocalDateTime updatedAt = LocalDateTime.now();

	@Column(name = "LAST_LOGIN_AT")
	private LocalDateTime lastLoginAt;
}
