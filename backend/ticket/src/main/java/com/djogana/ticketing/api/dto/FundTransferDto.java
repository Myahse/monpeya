package com.djogana.ticketing.api.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class FundTransferDto {

    /** Onafriq: WalletToCard, CardToWallet, C2C */
    @JsonProperty("transferType")
    @JsonAlias({"paymentType"})
    private String paymentType;

    @JsonAlias({"amount", "montant"})
    private Double transferAmount;

    /** ISO 4217, e.g. XOF for BNI Peya Pay */
    private String currencyCode;

    /** Source account — WalletToCard / CardToWallet / C2C */
    @JsonAlias({"distributionAccountId"})
    private Long fromAccountId;

    /** Destination account — WalletToCard / CardToWallet / C2C */
    @JsonAlias({"registrationAccountId", "accountId"})
    private Long toAccountId;

    /** Card-to-card (C2C) only */
    @JsonAlias({"memo", "reference"})
    private String referenceMemo;

    /** Card-to-card (C2C) only — must match registration mobile when required */
    @JsonAlias({"gsmPrincipale", "phoneNumber", "mobile", "numerotele", "mobilePhoneNumber"})
    private String mobilePhoneNumber;

    /** Last 4 digits of the card PAN */
    @JsonAlias({"last4", "registrationLast4Digits"})
    private String last4Digits;

    /** Card-to-card (C2C) only — ToCardAccount (default) or CardholderAccount */
    private String transactionIdAccount;

    /** WalletToCard Oracle debit — code client Peya (optionnel si lie via toAccountId) */
    @JsonAlias({"code_client"})
    private String codeClient;

    /** C2C / CardToWallet — reference memos sent to Onafriq */
    private String fromCardReferenceMemo;

    /** C2C / CardToWallet — reference memos sent to Onafriq */
    private String toCardReferenceMemo;
}
