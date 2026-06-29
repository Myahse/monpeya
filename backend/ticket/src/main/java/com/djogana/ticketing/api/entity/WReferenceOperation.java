package com.djogana.ticketing.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.io.Serializable;
import java.math.BigDecimal;

@Getter
@Setter
@Entity
@Table(name = "W_REFERENCE_OPERATION")
public class WReferenceOperation implements Serializable, Cloneable{
	@Id
	@Column(name = "IDREFERENCE_OPERATION")
	private BigDecimal idReferenceOperation;
	
	@Column(name = "CODE_BANQUE")
	private String codeBanque;
	
	
	@Column(name = "NUM_OPERATION")
	private String numOperation;
	
	@Column(name = "CODEOPERATION")
	private String codeOperation;

	public BigDecimal getIdReferenceOperation() {
		return idReferenceOperation;
	}

	public void setIdReferenceOperation(BigDecimal idReferenceOperation) {
		this.idReferenceOperation = idReferenceOperation;
	}

}
