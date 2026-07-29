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
@Table(name = "PAIEMENTS")
public class ImmoPaiement {

    @Id
    @Column(name = "PAIEMENTS_ID", length = 36)
    private String paiementsId;

    @Column(name = "MONTANT", nullable = false)
    private BigDecimal montant;

    @Column(name = "DATE_PAIEMENT")
    private LocalDateTime datePaiement;

    @Column(name = "COMMENTAIRE", length = 500)
    private String commentaire;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "LOCATAIRES_ID")
    private ImmoLocataire locataire;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "BIENS_ID")
    private ImmoBien bien;

    @Column(name = "UTILISATEURS_ID", length = 50)
    private String utilisateursId;

    @Column(name = "CONTRATS_LOCATION_ID", length = 36)
    private String contratsLocationId;
}
