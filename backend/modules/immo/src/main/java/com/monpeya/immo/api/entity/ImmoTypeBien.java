package com.monpeya.immo.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "TYPE_BIENS")
public class ImmoTypeBien {

    @Id
    @Column(name = "ID", length = 36)
    private String id;

    @Column(name = "LIBELLE", nullable = false, length = 200)
    private String libelle;

    @Column(name = "NOM", length = 200)
    private String nom;
}
