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
@Table(name = "CODE_PAYS")
public class ImmoCodePays {

    @Id
    @Column(name = "ID", length = 36)
    private String id;

    @Column(name = "NOM", nullable = false, length = 200)
    private String nom;

    @Column(name = "CODE", nullable = false, length = 10)
    private String code;
}
