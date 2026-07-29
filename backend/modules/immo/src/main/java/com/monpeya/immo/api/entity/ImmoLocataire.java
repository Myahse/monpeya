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
@Table(name = "LOCATAIRES")
public class ImmoLocataire {

    @Id
    @Column(name = "LOCATAIRES_ID", length = 36)
    private String locatairesId;

    @Column(name = "NOM", nullable = false, length = 200)
    private String nom;

    @Column(name = "PRENOMS", length = 200)
    private String prenoms;

    @Column(name = "EMAIL", length = 200)
    private String email;

    @Column(name = "TELEPHONE", length = 50)
    private String telephone;

    @Column(name = "CNI", length = 100)
    private String cni;

    @Column(name = "ADRESSE", length = 500)
    private String adresse;

    @Column(name = "PROFESSION", length = 200)
    private String profession;

    @Column(name = "REVENU_MENSUEL")
    private BigDecimal revenuMensuel;

    @Column(name = "DATE_NAISSANCE")
    private LocalDateTime dateNaissance;

    @Column(name = "STATUT", length = 50)
    private String statut;

    @Column(name = "PHOTO", length = 1000)
    private String photo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "BIENS_ID")
    private ImmoBien bien;

    @Column(name = "UTILISATEURS_ID", length = 50)
    private String utilisateursId;

    @Column(name = "MONTANT_LOYER")
    private BigDecimal montantLoyer;

    @Column(name = "FREQUENCE_PAIEMENT", length = 50)
    private String frequencePaiement;

    @Column(name = "DATE_DEBUT_BAIL")
    private LocalDateTime dateDebutBail;

    @Column(name = "DATE_FIN_BAIL")
    private LocalDateTime dateFinBail;

    @Column(name = "JOUR_PAIEMENT")
    private Integer jourPaiement;
}
