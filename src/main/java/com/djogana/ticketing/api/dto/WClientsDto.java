package com.djogana.ticketing.api.dto;

import java.math.BigDecimal;

import lombok.Data;

/**
 * Read-only snapshot from {@code W_Clients} (+ optional {@code W_Comptes} for wallet).
 */
@Data
public class WClientsDto {

	private String codeClient;
	private String nomClient;
	private String gsmPrincipale;
	private String email;
	private String login;
	private String codeBanque;
	private String accountId;

	/** Primary Peya account number (from W_Comptes), used for wallet debit. */
	private String numerocomptecomplet;

	/** Available balance on the Peya account (read-only). */
	private BigDecimal soldeDispo;
}
