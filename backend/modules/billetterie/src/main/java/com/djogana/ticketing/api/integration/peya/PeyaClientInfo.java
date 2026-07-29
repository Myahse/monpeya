package com.djogana.ticketing.api.integration.peya;

import java.math.BigDecimal;

import lombok.Data;

/**
 * Read-only client snapshot from Peya API {@code /wClients/rechercheclient}.
 */
@Data
public class PeyaClientInfo {

	private String codeClient;
	private String nomClient;
	private String gsmPrincipale;
	private String email;
	private String login;
	private String codeBanque;
	private String accountId;
	private String numerocomptecomplet;
	private BigDecimal soldeDispo;
}
