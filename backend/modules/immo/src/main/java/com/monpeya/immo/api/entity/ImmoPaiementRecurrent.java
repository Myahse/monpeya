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
@Table(name = "PAIEMENTS_RECURRENTS")
public class ImmoPaiementRecurrent {

    @Id
    @Column(name = "PAIEMENTS_RECURRENTS_ID", length = 36)
    private String paiementsRecurrentsId;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "CONTRATS_LOCATION_ID", nullable = false)
    private ImmoContratLocation contrat;

    @Column(name = "UTILISATEURS_ID", length = 50)
    private String utilisateursId;

    @Column(name = "MONTANT", nullable = false)
    private BigDecimal montant;

    @Column(name = "FREQUENCE", length = 50)
    private String frequence;

    @Column(name = "PROCHAIN_PAIEMENT")
    private LocalDateTime prochainPaiement;

    @Column(name = "DERNIER_PAIEMENT")
    private LocalDateTime dernierPaiement;

    @Column(name = "STATUT", length = 50)
    private String statut;

    @Column(name = "DATE_CREATION")
    private LocalDateTime dateCreation;
}
