package com.djogana.ticketing.api.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;

import java.math.BigDecimal;
import java.util.Date;

@JsonPropertyOrder(alphabetic = true)
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CommissionDto {

	String codePack;
	String codeOperationBq;
	Integer montant;
	String codeBq;
	String codeOp;
	String compteComplet;
	String sOrig;
	String criteref;
	String ncgcpt;
	String forfait;
	String compte;
	String interdit;
	String referRenceOperation;
	BigDecimal statusColonne;
	String codeAgence;
	String login;
	String codeClient;
	String codeCaisse;
	String codeProd;
	String referenceInit;
	Integer montantComm;
	String p1;
	String p2;
	String mgrp;
	BigDecimal idTaxeContrib;
	String taxeClient;
	String psite;
	String pclient;
	String ptaxe;
	String motif;
	String fichier;

	private String dateBordereau;
	private String motifBordereau;
	private String referenceBordereau;

	public String getDateBordereau() {
		return dateBordereau;
	}

	public void setDateBordereau(String dateBordereau) {
		this.dateBordereau = dateBordereau;
	}

	public String getMotifBordereau() {
		return motifBordereau;
	}

	public void setMotifBordereau(String motifBordereau) {
		this.motifBordereau = motifBordereau;
	}

	public String getReferenceBordereau() {
		return referenceBordereau;
	}

	public void setReferenceBordereau(String referenceBordereau) {
		this.referenceBordereau = referenceBordereau;
	}

	String pProduit;

	public String getpProduit() {
		return pProduit;
	}

	public void setpProduit(String pProduit) {
		this.pProduit = pProduit;
	}

	public String getFichier() {
		return fichier;
	}

	public void setFichier(String fichier) {
		this.fichier = fichier;
	}

	public String getMotif() {
		return motif;
	}

	public void setMotif(String motif) {
		this.motif = motif;
	}

	public String getPtaxe() {
		return ptaxe;
	}

	public void setPtaxe(String ptaxe) {
		this.ptaxe = ptaxe;
	}

	public String getPsite() {
		return psite;
	}

	public void setPsite(String psite) {
		this.psite = psite;
	}

	public String getPclient() {
		return pclient;
	}

	public void setPclient(String pclient) {
		this.pclient = pclient;
	}

	public BigDecimal getIdTaxeContrib() {
		return idTaxeContrib;
	}

	public void setIdTaxeContrib(BigDecimal idTaxeContrib) {
		this.idTaxeContrib = idTaxeContrib;
	}

	public String getTaxeClient() {
		return taxeClient;
	}

	public void setTaxeClient(String taxeClient) {
		this.taxeClient = taxeClient;
	}

	public String getMgrp() {
		return mgrp;
	}

	public void setMgrp(String mgrp) {
		this.mgrp = mgrp;
	}

	public String getP1() {
		return p1;
	}

	public void setP1(String p1) {
		this.p1 = p1;
	}

	public String getP2() {
		return p2;
	}

	public void setP2(String p2) {
		this.p2 = p2;
	}

	public String getCodeProd() {
		return codeProd;
	}

	public void setCodeProd(String codeProd) {
		this.codeProd = codeProd;
	}

	public String getReferenceInit() {
		return referenceInit;
	}

	public void setReferenceInit(String referenceInit) {
		this.referenceInit = referenceInit;
	}

	public Integer getMontantComm() {
		return montantComm;
	}

	public void setMontantComm(Integer montantComm) {
		this.montantComm = montantComm;
	}

	public String getCodeCaisse() {
		return codeCaisse;
	}

	public void setCodeCaisse(String codeCaisse) {
		this.codeCaisse = codeCaisse;
	}

	public String getCodeClient() {
		return codeClient;
	}

	public void setCodeClient(String codeClient) {
		this.codeClient = codeClient;
	}

	private Double commission;
	private Double timbre;

	public Double getCommission() {
		return commission;
	}

	public void setCommission(Double commission) {
		this.commission = commission;
	}

	public Double getTimbre() {
		return timbre;
	}

	public void setTimbre(Double timbre) {
		this.timbre = timbre;
	}

	public Double getTotalCommission() {
		return commission + timbre;
	}

	public String getCodePack() {
		return codePack;
	}

	public void setCodePack(String codePack) {
		this.codePack = codePack;
	}

	public String getCodeOperationBq() {
		return codeOperationBq;
	}

	public void setCodeOperationBq(String codeOperationBq) {
		this.codeOperationBq = codeOperationBq;
	}

	public Integer getMontant() {
		return montant;
	}

	public void setMontant(Integer montant) {
		this.montant = montant;
	}

	public String getCodeBq() {
		return codeBq;
	}

	public void setCodeBq(String codeBq) {
		this.codeBq = codeBq;
	}

	public String getCodeOp() {
		return codeOp;
	}

	public void setCodeOp(String codeOp) {
		this.codeOp = codeOp;
	}

	public String getCompteComplet() {
		return compteComplet;
	}

	public void setCompteComplet(String compteComplet) {
		this.compteComplet = compteComplet;
	}

	public String getsOrig() {
		return sOrig;
	}

	public void setsOrig(String sOrig) {
		this.sOrig = sOrig;
	}

	public String getCriteref() {
		return criteref;
	}

	public void setCriteref(String criteref) {
		this.criteref = criteref;
	}

	public String getNcgcpt() {
		return ncgcpt;
	}

	public void setNcgcpt(String ncgcpt) {
		this.ncgcpt = ncgcpt;
	}

	public String getForfait() {
		return forfait;
	}

	public void setForfait(String forfait) {
		this.forfait = forfait;
	}

	public String getCompte() {
		return compte;
	}

	public void setCompte(String compte) {
		this.compte = compte;
	}

	public String getInterdit() {
		return interdit;
	}

	public void setInterdit(String interdit) {
		this.interdit = interdit;
	}

	public String getReferRenceOperation() {
		return referRenceOperation;
	}

	public void setReferRenceOperation(String referRenceOperation) {
		this.referRenceOperation = referRenceOperation;
	}

	public BigDecimal getStatusColonne() {
		return statusColonne;
	}

	public void setStatusColonne(BigDecimal statusColonne) {
		this.statusColonne = statusColonne;
	}

	public String getCodeAgence() {
		return codeAgence;
	}

	public void setCodeAgence(String codeAgence) {
		this.codeAgence = codeAgence;
	}

	public String getLogin() {
		return login;
	}

	public void setLogin(String login) {
		this.login = login;
	}

}


