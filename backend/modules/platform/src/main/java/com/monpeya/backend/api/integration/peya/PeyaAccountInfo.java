package com.monpeya.backend.api.integration.peya;

import java.math.BigDecimal;

import lombok.Data;

/** One {@code datasCompte} entry from Peya wclients payloads. */
@Data
public class PeyaAccountInfo {
	private String codeClient;
	private String numerocomptecomplet;
	private String nomDuCompte;
	private String codeBanque;
	private String codeAgence;
	private String typeCompte;
	private BigDecimal soldeDispo;
	private BigDecimal soldeCompta;
	private boolean principal;
}
