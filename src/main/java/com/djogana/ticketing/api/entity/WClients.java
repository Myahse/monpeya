package com.djogana.ticketing.api.entity;

import java.math.BigDecimal;
import java.util.Date;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import lombok.Getter;
import lombok.Setter;

/**
 * Read-only Peya client identity. Ticketing stores {@code codeClient} on T_* tables;
 * other columns are loaded when needed (display, wallet debit) but never written back.
 */
@Entity
@Getter
@Setter
@Table(name = "W_Clients")
public class WClients {

	@Id
	@Column(name = "CODE_CLIENT")
	private String codeClient;

	@Column(name = "EMAIL")
	private String email;

	@Column(name = "GSMPRINCIPALE")
	private String gsmPrincipale;

	@Column(name = "CODE_BANQUE")
	private String codeBanque;

	@Column(name = "ACCOUND_ID", length = 100)
	private String accountId;

	@JsonIgnore
	@Column(name = "PASSWORD")
	private String password;

	@Temporal(TemporalType.TIMESTAMP)
	@Column(name = "DATECONNEXION")
	private Date dateConnexion;

	@Column(name = "NOMCLIENT")
	private String nomClient;

	@Column(name = "ETAT")
	private BigDecimal etat;

	@Column(name = "LOGINCLIENT")
	private String loginClient;

	@Column(name = "LOGIN")
	private String login;
}
