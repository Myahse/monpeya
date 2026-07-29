package com.djogana.ticketing.api.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import jakarta.persistence.Column;
import jakarta.persistence.Id;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.math.BigDecimal;
import java.util.Date;

@Getter
@Setter
@ToString
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonPropertyOrder(alphabetic = true)
public class WRetraitDto {
    private String codeoperation;
    private Date dateoperation;
    private Date heureOperation;
    private String numeroCompte;
    private String codeBanque;
    private String codeAgence;
    private String login;
    private String codeCaisse;
    private BigDecimal montant;
    private String compteCommission;
    private Double montantCommision;
    private String compteCredit;
    private BigDecimal montantCredit;
    private String codeoperationbq;
    private String numretrait;
    private String compteTaxe;
    private BigDecimal montantTaxe;
    private String rap;
    private String vrap;
    private String x1;
}
