package com.djogana.ticketing.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@Entity
@Table(name = "W_TOUS")
public class WTous {

    @Id
    @Column(name = "IDW_TOUS")
    private BigDecimal id;

    @Column(name = "CODE_BANQUE")
    private String codeBanque;

    @Column(name = "CPT")
    private String cpt;

    @Column(name = "CODETOUS")
    private String codeTous;

    @Column(name = "DIVERS1")
    private String divers1;

    @Column(name = "DIVERS2")
    private String divers2;

    @Column(name = "DIVERS3")
    private String divers3;
}

