package com.djogana.ticketing.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;

@Entity
@Table(name="W_SEQUENCE" )
public class WSequence {

    @Column(name="INDICE_SEQ")
    private BigDecimal indiceSeq ;

	@Id
	@Column(name="NOM_FICHIER")
    private String nomFichier;

	
	public BigDecimal getIndiceSeq() {
		return indiceSeq;
	}

	public void setIndiceSeq(BigDecimal indiceSeq) {
		this.indiceSeq = indiceSeq;
	}

	public String getNomFichier() {
		return nomFichier;
	}

	public void setNomFichier(String nomFichier) {
		this.nomFichier = nomFichier;
	}
	
	
}
