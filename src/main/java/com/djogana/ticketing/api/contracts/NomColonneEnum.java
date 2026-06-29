package com.djogana.ticketing.api.contracts;

public enum NomColonneEnum {

    TRANSFERT("NUMTRANSFERT"), RETRAIT("NUMRETRAIT"), VIREMENT("NUMGUICHET"), GUICHET("NUMGUICHET"),
    TABLERETRAIT("NUMGUICHET"), PAIEMENT("NUMGUICHET"), MARCHAND("NUMGUICHET");

    private final String _value;

    NomColonneEnum(String value) {
        _value = value;
    }

    public String getValue() {
        return _value;
    }

    public static String getLabel(String id) {
        String labelString = "COL_ND";
        switch (id) {
            case "TRANSFERT":
            case "TRS":
                labelString = TRANSFERT._value;
                break;
            case "RETRAIT":
            case "RET":
                labelString = RETRAIT._value;
                break;
            case "VIREMENT":
            case "PAS":
            case "VIR":
                labelString = VIREMENT._value;
                break;
            case "DES":
                labelString = VIREMENT._value;
                break;
            case "GUICHET":
            case "DEP":
                labelString = GUICHET._value;
                break;
            case "PAY":
                labelString = PAIEMENT._value;
                break;
            case "FAC":
                labelString = PAIEMENT._value;
                break;
            case "TABLERETRAIT":
            case "REP":
                labelString = TABLERETRAIT._value;
                break;
            case "DTP":
                labelString = MARCHAND._value;
                break;
            case "RER":
                labelString = RETRAIT._value;
                break;
            case "DER":
                labelString = GUICHET._value;
        }

        return labelString;
    }
}