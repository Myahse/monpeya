package com.monpeya.immo.api.entity;

import java.math.BigDecimal;
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
@Table(name = "CONTRATS_LOCATION")
public class ImmoContratLocation {

    @Id
    @Column(name = "CONTRATS_LOCATION_ID", length = 36)
    private String contratsLocationId;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "BIENS_ID", nullable = false)
    private ImmoBien bien;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "LOCATAIRES_ID", nullable = false)
    private ImmoLocataire locataire;

    @Column(name = "UTILISATEURS_ID", length = 50)
    private String utilisateursId;

    @Column(name = "MONTANT_LOYER")
    private BigDecimal montantLoyer;

    @Column(name = "FREQUENCE_PAIEMENT", length = 50)
    private String frequencePaiement;

    @Column(name = "JOUR_PAIEMENT")
    private Integer jourPaiement;

    @Column(name = "DATE_DEBUT")
    private LocalDateTime dateDebut;

    @Column(name = "DATE_FIN")
    private LocalDateTime dateFin;

    @Column(name = "STATUT", length = 50)
    private String statut;

    @Column(name = "DATE_CREATION")
    private LocalDateTime dateCreation;
}
