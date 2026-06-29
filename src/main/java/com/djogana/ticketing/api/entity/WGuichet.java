package com.djogana.ticketing.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.Date;

@Getter
@Setter
@Entity
@Table(name = "W_GUICHET")
public class WGuichet {

    @Column(name = "CODEOPERATION")
    private String codeOperation;

    @Column(name = "MONTANTDEB")
    private BigDecimal montantdeb;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "DATEOPERATION")
    private Date dateoperation;

    @Column(name = "HEUREOPERATION")
    private Date heureoperation;

    @Id
    @Column(name = "NUMGUICHET")
    private String numguichet;

    @Column(name = "CODE_AGENCE")
    private String codeAgence;

    @Column(name = "CODE_BANQUE")
    private String codeBanque;

    @Column(name = "TIMBRE")
    private Double timbre;

    @Column(name = "MONTANT_COMMISION")
    private Double montantCommision;

    @Column(name = "COMPTE_DEBIT")
    private String compteDebit;

    @Column(name = "PLATEFORM")
    private String plateform;

    @Column(name = "COMPTE_CREDIT")
    private String compteCredit;

    @Column(name = "MONTANTCRE")
    private BigDecimal montantcre;

    @Column(name = "MONTANT")
    private BigDecimal montant;

    @Column(name = "COMPTE_COMMISSION")
    private String compteCommission;

    @Column(name = "COMPTE_TIMBRE")
    private String compteTimbre;

    @Column(name = "MONTANTTAXE")
    private BigDecimal montanttaxe;

    @Column(name = "COMPTE_TAXE")
    private String compteTaxe;

    @Column(name = "LOGIN")
    private String login;

    @Column(name = "CODEOPERATIONBQ")
    private String codeoperationbq;

    @Column(name = "RAP")
    private String rap;

    @Column(name = "VRAP")
    private String vrap;

    @Column(name = "X1")
    private String x1;

    @Column(name = "CPT_COMP_INIT")
    private String cptCompInit;

    @Column(name = "CPT_COMP_FIN")
    private String cptCompFin;

    @Column(name = "v_x1")
    private String vx1;

    @Column(name = "v_x2")
    private String vx2;

    @Column(name = "v_x3")
    private String vx3;

    @Column(name = "v_x4")
    private String vx4;

    @Column(name = "v_x5")
    private String vx5;

    @Column(name = "v_x6")
    private String vx6;

    @Column(name = "v_x7")
    private String vx7;

    @Column(name = "v_x8")
    private String vx8;

    @Column(name = "v_x9")
    private String vx9;

    @Column(name = "TDS_ID")
    private BigDecimal tdsId;
}

