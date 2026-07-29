package com.monpeya.immo.api.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "BIENS")
public class ImmoBien {

    @Id
    @Column(name = "BIENS_ID", length = 36)
    private String biensId;

    @Column(name = "NOM", nullable = false, length = 300)
    private String nom;

    @Column(name = "DESCRIPTION")
    private String description;

    @Column(name = "PRIX")
    private BigDecimal prix;

    @Column(name = "SUPERFICIE")
    private BigDecimal superficie;

    @Column(name = "ADRESSE", length = 500)
    private String adresse;

    @Column(name = "VILLE", length = 200)
    private String ville;

    @Column(name = "CODE_POSTAL", length = 20)
    private String codePostal;

    @Column(name = "LATITUDE")
    private BigDecimal latitude;

    @Column(name = "LONGITUDE")
    private BigDecimal longitude;

    @Column(name = "PHOTO")
    private String photo;

    @Column(name = "COMMODITIES")
    private String commodities;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "TYPE_BIENS_ID")
    private ImmoTypeBien typeBiens;

    @Column(name = "STATUT", length = 50)
    private String statut;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "CODE_PAYS_ID")
    private ImmoCodePays codePays;

    @Column(name = "UTILISATEURS_ID", length = 50)
    private String utilisateursId;

    @Column(name = "DATE_CREATION")
    private LocalDateTime dateCreation;

    @Column(name = "DATE_ACQUISITION")
    private LocalDate dateAcquisition;

    @Column(name = "EVALUATION_QUALITE")
    private BigDecimal evaluationQualite;
}
