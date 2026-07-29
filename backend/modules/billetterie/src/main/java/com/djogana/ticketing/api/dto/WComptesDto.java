package com.djogana.ticketing.api.dto;

import com.djogana.ticketing.api.contracts.SearchParam;
import com.djogana.ticketing.api.entity.WClients;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

@Getter
@Setter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class WComptesDto {

    private BigDecimal idwComptes;
    private String codeClient;
    private WClients wClients;
    private Date dateouverture;
    private Date datefermture;
    private String codeexplvalidation;
    private String codedevise;
    private BigDecimal soldedispo;
    private BigDecimal soldecompta;
    private BigDecimal soldeautorisation;
    private Date datederniermvt;
    private String codeBanque;
    private String codeAgence;
    private String nomDuCompte;
    private List<WComptesDto> datasCompte;

    private String codeSur;
    private String numerocomptecomplet;
    private String ngc;
    private BigDecimal bloquage;
    private String codePack;
    private String ncpteParrain;

    // Search param
    private SearchParam<BigDecimal>idwComptesParam       ;
    private SearchParam<String>   codeClientParam       ;
    private SearchParam<String>   typeCompteParam       ;
    private SearchParam<String>   numeroCompteParam     ;
    private SearchParam<String>   codeexplParam         ;
    private SearchParam<String>   gestionnaireParam     ;
    private SearchParam<String>   dateouvertureParam    ;
    private SearchParam<String>   datefermtureParam     ;
    private SearchParam<String>   codeexplvalidationParam;
    private SearchParam<String>   codedeviseParam       ;
    private SearchParam<BigDecimal>soldedispoParam       ;
    private SearchParam<BigDecimal>soldeenattenteParam   ;
    private SearchParam<BigDecimal>soldecomptaParam      ;
    private SearchParam<BigDecimal>soldeautorisationParam;
    private SearchParam<BigDecimal>champsurveillanceParam;
    private SearchParam<String>   datederniermvtParam   ;
    private SearchParam<String>   codeBanqueParam       ;
    private SearchParam<String>   codeAgenceParam       ;
    private SearchParam<String> motifFermertureParam  ;
    private SearchParam<String>   clefRibParam          ;
    private SearchParam<BigDecimal>tcoIdParam            ;
    private SearchParam<String>   codeSurParam          ;
    private SearchParam<String>   numerocomptecompletParam;
    private SearchParam<String>   loginParam            ;
    private SearchParam<String>   ngcParam              ;
    private SearchParam<String>   loginexplParam        ;
    private SearchParam<String>   nomducompteParam      ;
    private SearchParam<String>   codeorigsysParam      ;
    private SearchParam<BigDecimal>codeParam             ;
    private SearchParam<String>   indiceCptParam        ;
    private SearchParam<String>   numcptorigcbqParam    ;
    private SearchParam<String>   ncpteAbonneeParam     ;
    private SearchParam<BigDecimal>bloquageParam         ;
    private SearchParam<String>   codePackParam         ;
    private SearchParam<String>   ncpteParrainParam     ;
    private SearchParam<BigDecimal>compteFacturationParam;

}
