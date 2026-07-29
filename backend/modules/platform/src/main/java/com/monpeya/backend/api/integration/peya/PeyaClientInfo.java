package com.monpeya.backend.api.integration.peya;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import lombok.Data;

/**
 * Client snapshot from Peya ({@code rechercheGsm}, {@code etatclient}, {@code rechercheclient}).
 */
@Data
public class PeyaClientInfo {

	private String codeClient;
	private String nomClient;
	private String firstName;
	private String lastName;
	private String gsmPrincipale;
	private String email;
	private String login;
	private String codeBanque;
	private String accountId;
	private String numerocomptecomplet;
	private BigDecimal soldeDispo;
	/** NEW_CUSTOMER | CODE_PIN | CUSTOMER */
	private String etatClient;
	private String codePaysResidence;
	private LocalDate birthDate;
	private String idNumber;
	private String adresse;
	private String profession;
	private String lieuNaissance;
	/**
	 * Supplier / merchant: has at least one {@code datasCompte.typcpt = S}
	 * (from {@code /wClients/rechercheclient}).
	 */
	private boolean peyapayMerchant;
	/** Peya root {@code deplafonner} — required before CLIENT straight subscribe debit. */
	private boolean deplafonne;
	/** True when {@code deplafonner} was present on the rechercheclient item. */
	private boolean deplafonnePresent;
	private List<PeyaAccountInfo> accounts = new ArrayList<>();
}
