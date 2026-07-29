package com.djogana.ticketing.api.contracts;

public class AutoriseOn {
    private String codeoperation;
    private String codeoperationBq;
    private String ncgCompteDebit;
    private String ncgCompteCredit;
    private String compteDebit;
    private String compteCredit;

    public String getCodeoperation() {
        return codeoperation;
    }

    public void setCodeoperation(String codeoperation) {
        this.codeoperation = codeoperation;
    }

    public String getCodeoperationBq() {
        return codeoperationBq;
    }

    public void setCodeoperationBq(String codeoperationBq) {
        this.codeoperationBq = codeoperationBq;
    }

    public String getNcgCompteDebit() {
        return ncgCompteDebit;
    }

    public void setNcgCompteDebit(String ncgCompteDebit) {
        this.ncgCompteDebit = ncgCompteDebit;
    }

    public String getNcgCompteCredit() {
        return ncgCompteCredit;
    }

    public void setNcgCompteCredit(String ncgCompteCredit) {
        this.ncgCompteCredit = ncgCompteCredit;
    }

    public String getCompteDebit() {
        return compteDebit;
    }

    public void setCompteDebit(String compteDebit) {
        this.compteDebit = compteDebit;
    }

    public String getCompteCredit() {
        return compteCredit;
    }

    public void setCompteCredit(String compteCredit) {
        this.compteCredit = compteCredit;
    }
}
