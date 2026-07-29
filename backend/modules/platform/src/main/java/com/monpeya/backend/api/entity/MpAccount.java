package com.monpeya.backend.api.entity;

import java.math.BigDecimal;
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
@Table(name = "MP_ACCOUNT")
public class MpAccount {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_account_seq")
	@SequenceGenerator(name = "mp_account_seq", sequenceName = "MP_ACCOUNT_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "USER_ID", nullable = false)
	private MpUser user;

	@Column(name = "CODE_CLIENT", length = 50)
	private String codeClient;

	@Column(name = "NUMERO_COMPTE_COMPLET", length = 100)
	private String numerocomptecomplet;

	@Column(name = "NOM_DU_COMPTE", length = 200)
	private String nomDuCompte;

	@Column(name = "CODE_BANQUE", length = 20)
	private String codeBanque;

	@Column(name = "CODE_AGENCE", length = 20)
	private String codeAgence;

	@Column(name = "TYPE_COMPTE", length = 20)
	private String typeCompte;

	@Column(name = "SOLDE_DISPO")
	private BigDecimal soldeDispo;

	@Column(name = "SOLDE_COMPTA")
	private BigDecimal soldeCompta;

	@Column(name = "IS_PRINCIPAL", nullable = false)
	private Boolean isPrincipal = false;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();

	@Column(name = "UPDATED_AT", nullable = false)
	private LocalDateTime updatedAt = LocalDateTime.now();
}
