package com.djogana.ticketing.api.contracts;

import com.djogana.ticketing.api.repository.*;
import com.djogana.ticketing.api.entity.WComptes;
import com.djogana.ticketing.api.entity.WReferenceOperation;
import com.djogana.ticketing.api.entity.WSequence;
import com.djogana.ticketing.api.dto.CommissionDto;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Random;

@Component
public class FarfarUtils {

    private static final Logger log = LoggerFactory.getLogger(FarfarUtils.class);

    @Autowired
    private WComptesRepository wComptesRepository;

    @Autowired
    private WReferenceOperationRepository wReferenceOperationRepository;

    @Autowired
    private FunctionalError functionalError;
    @Autowired
    private TechnicalError technicalError;
    @Autowired
    private ExceptionUtils exceptionUtils;

    @Autowired
    private WRetraitRepository wRetraitRepository;

    @Autowired
    private WSequenceRepository wSequenceRepository;


    @PersistenceContext
    private EntityManager em;

    private Response<CommissionDto> response;

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> rechercheCommission(CommissionDto dto, Locale locale) {

        response = new Response<>();
        Double commission = 0.0;
        Double timbre = 0.0;
        // String ncgcpt = "";
        String codeTypeTimbre = "";
        String codeTypeTimbre1 = "";
        String codeTypeCommission = "";
        String codeTypeCommission1 = "";
        String sVal = "A";
        List<Map<String, Object>> exceptionInfoList;
        List<Map<String, Object>> infosTimbre;
        List<Map<String, Object>> infosTimbresException;
        List<Map<String, Object>> infoscommission;
        List<Map<String, Object>> infoscommissionException;
        if (dto.getsOrig().equals("W")) {
            // verifie si il y a exception sur le compte
            exceptionInfoList = wRetraitRepository.getTypeOperationException(dto.getCompteComplet(), dto.getCodeOp(),
                    dto.getCodeBq(), dto.getCodeOperationBq(), dto.getCodePack());
            if (Utilities.isNotEmpty(exceptionInfoList)) {
                sVal = "X";
            }

        } else if (dto.getsOrig().equals("P")) {

        } else {
            response.setHasError(true);
            response.setStatus(functionalError.DISALLOWED_OPERATION("Type de compte non dédini", locale));
            return response;
        }

        switch (sVal) {
            case "A":

                String montantTimbre = "MNTTIMBRE";
                String montantCommission = "MNTCOM";

                codeTypeCommission1 = String.format("%s%s%s%s%s%s", dto.getCodePack(), montantCommission, dto.getNcgcpt(),
                        dto.getCodeOp(), dto.getCodeBq(), dto.getCodeOperationBq());
                codeTypeCommission = String.format("%s%s", codeTypeCommission1, dto.getCriteref());

                codeTypeTimbre1 = String.format("%s%s%s%s%s%s", dto.getCodePack(), montantTimbre, dto.getNcgcpt(),
                        dto.getCodeOp(), dto.getCodeBq(), dto.getCodeOperationBq());
                codeTypeTimbre = String.format("%s%s", codeTypeTimbre1, dto.getCriteref());

                infosTimbre = wRetraitRepository.getInfosTimbre(codeTypeTimbre);
                if (Utilities.isEmpty(infosTimbre)) {
                    dto.setTimbre((double) 0);
                } else {
                    if (Double.parseDouble(infosTimbre.get(0).get("MNTMIN").toString()) <= Double.valueOf(dto.getMontant().intValue())) {
                        dto.setTimbre(Double.parseDouble(infosTimbre.get(0).get("VALEUR").toString()));
                    } else {
                        dto.setTimbre((double) 0);
                    }

                }

                infoscommission = wRetraitRepository.getInfosCommission(codeTypeCommission);
                if (Utilities.isEmpty(infoscommission)) {

                    dto.setCommission((double) 0);
                    response.setItem(dto);
                    return response;

                }

                for (Map<String, Object> infoscommissionDetail : infoscommission) {
                    if (Double.parseDouble(infoscommissionDetail.get("MNTMIN").toString()) <= dto.getMontant().intValue()
                            && Integer.parseInt(infoscommissionDetail.get("MNTMAX").toString()) >= dto.getMontant()
                            .intValue()) {
                        if (Integer.parseInt(infoscommissionDetail.get("ACTIFBK").toString()) == 1) {
                            Integer type = Integer.parseInt(infoscommissionDetail.get("TYPE").toString());
                            switch (type) {
                                case 2:
                                    infoscommissionException = wRetraitRepository
                                            .getInfosCommissionException(codeTypeCommission1, dto.getCriteref());
                                    if (Utilities.isEmpty(infoscommissionException)) {
                                        response.setHasError(true);
                                        response.setStatus(functionalError.DISALLOWED_OPERATION(
                                                "Impossible de recupérer les informations sur la commission du compte actif",
                                                locale));
                                        return response;
                                    }
                                    for (Map<String, Object> infoscommissionExceptionDetail : infoscommissionException) {
                                        if (Integer.parseInt(infoscommissionExceptionDetail.get("MINIMUN").toString()) <= dto
                                                .getMontant().intValue()
                                                && Integer.parseInt(infoscommissionExceptionDetail.get("MAXIMUN")
                                                .toString()) >= dto.getMontant().intValue()) {
                                            commission = Double
                                                    .parseDouble(infoscommissionExceptionDetail.get("FRAIS").toString());
                                        }
                                    }
                                    break;
                                case 1:
                                    if (Utilities.isEmpty(infoscommission)) {
                                        response.setHasError(true);
                                        response.setStatus(functionalError.DISALLOWED_OPERATION(
                                                "Impossible de récupérer la valeur de la commission", locale));
                                        return response;
                                    }
                                    // Map<String, Object> infoscommissionDetailx = infoscommission.get(0);
                                    commission = Double.parseDouble(infoscommissionDetail.get("VALEUR").toString());
                                    break;
                                case 3:
                                    if (Utilities.isEmpty(infoscommission)) {
                                        response.setHasError(true);
                                        response.setStatus(functionalError
                                                .DISALLOWED_OPERATION("Impossible de calculer la commission", locale));
                                        return response;
                                    }
                                    // Map<String, Object> infoscommissionDetaily = infoscommission.get(0);
                                    Double val = Double.parseDouble(infoscommissionDetail.get("VALEUR").toString());
                                    commission = (double) Math.round(dto.getMontant().doubleValue() * val / 100);
                                    if (commission < Double.parseDouble(infoscommissionDetail.get("MNTLIM").toString()))
                                        commission = Double.parseDouble(infoscommissionDetail.get("MNTLIM").toString());
                                    break;
                            }
                        }
                    }
                }
                // recherche Timbre
                for (Map<String, Object> infostimbreDetail : infosTimbre) {
                    if (Integer.parseInt(infostimbreDetail.get("MNTMIN").toString()) <= dto.getMontant().intValue()
                            && Integer.parseInt(infostimbreDetail.get("MNTMAX").toString()) >= dto.getMontant()
                            .intValue()) {
                        if (Integer.parseInt(infostimbreDetail.get("ACTIFBK").toString()) == 1) {
                            Integer type = Integer.parseInt(infostimbreDetail.get("TYPE").toString());
                            switch (type) {
                                case 2:
                                    infosTimbresException = wRetraitRepository.getInfosTimbreException(codeTypeTimbre1,
                                            dto.getCriteref());
                                    if (Utilities.isEmpty(infosTimbresException)) {
                                        response.setHasError(true);
                                        response.setStatus(functionalError.DISALLOWED_OPERATION(
                                                "Impossible de recupérer les informations sur la commission du compte actif",
                                                locale));
                                        return response;
                                    }
                                    for (Map<String, Object> infostimbreExceptionDetail : infosTimbresException) {
                                        if (Integer.parseInt(infostimbreExceptionDetail.get("MINIMUN").toString()) <= dto
                                                .getMontant().intValue()
                                                && Integer.parseInt(infostimbreExceptionDetail.get("MAXIMUN").toString()) >= dto
                                                .getMontant().intValue()) {
                                            timbre = Double.parseDouble(infostimbreExceptionDetail.get("FRAIS").toString());
                                        }
                                    }
                                    break;
                                case 1:
                                    if (Utilities.isEmpty(infosTimbre)) {
                                        response.setHasError(true);
                                        response.setStatus(functionalError
                                                .DISALLOWED_OPERATION("Impossible de récupérer la valeur timbre", locale));
                                        return response;
                                    }

                                    // Map<String, Object> infostimbreDetailx = infosTimbre.get(0);
                                    timbre = Double.parseDouble(infostimbreDetail.get("VALEUR").toString());
                                    break;
                                case 3:
                                    if (Utilities.isEmpty(infosTimbre)) {
                                        response.setHasError(true);
                                        response.setStatus(functionalError
                                                .DISALLOWED_OPERATION("Impossible de calculer la commission", locale));
                                        return response;
                                    }
                                    // Map<String, Object> infostimbreDetaily = infostimbreDetail;
                                    Integer val = Integer.parseInt(infostimbreDetail.get("VALEUR").toString());
                                    commission = (double) Math.round(dto.getMontant().intValue() * val / 100);
                                    if (timbre < Integer.parseInt(infostimbreDetail.get("MNTLIM").toString()))
                                        timbre = Double.parseDouble(infostimbreDetail.get("MNTLIM").toString());
                                    break;
                            }
                        }
                    }
                }

                /** Fin de la recuperation de la commission et timbre **/
                break;

            case "X":
                String montantCommissionx = "MNTCOM";
                codeTypeCommission1 = String.format("%s%s%s%s%s%s", dto.getCodePack(), montantCommissionx,
                        dto.getCompteComplet(), dto.getCodeOp(), dto.getCodeBq(), dto.getCodeOperationBq());

                codeTypeCommission = String.format("%s%s", codeTypeCommission1, dto.getCriteref());
                infoscommission = wRetraitRepository.getInfosCommission(codeTypeCommission);
                if (Utilities.isEmpty(infoscommission)) {
                    dto.setCommission((double) 0);
                    response.setItem(dto);
                    return response;

//				response.setHasError(true);
//				response.setStatus(functionalError
//						.DISALLOWED_OPERATION("Impossible de recupérer les informations sur la commission", locale));
//				return response;
                }
                for (Map<String, Object> infoscommissionDetail : infoscommission) {
                    if (Integer.parseInt(infoscommissionDetail.get("MNTMIN").toString()) <= dto.getMontant().intValue()
                            && Integer.parseInt(infoscommissionDetail.get("MNTMAX").toString()) >= dto.getMontant()
                            .intValue()) {
                        if (Integer.parseInt(infoscommissionDetail.get("ACTIFBK").toString()) == 1) {
                            switch (Integer.parseInt(infoscommissionDetail.get("TYPE").toString())) {
                                case 2:
                                    infoscommissionException = wRetraitRepository
                                            .getInfosCommissionException(codeTypeCommission1, dto.getCriteref());
                                    if (Utilities.isEmpty(infoscommissionException)) {
                                        response.setHasError(true);
                                        response.setStatus(functionalError.DISALLOWED_OPERATION(
                                                "Impossible de recupérer les informations sur la commission du compte actif",
                                                locale));
                                        return response;
                                    }
                                    for (Map<String, Object> infoscommissionExceptionDetail : infoscommissionException) {
                                        if (Integer.parseInt(infoscommissionExceptionDetail.get("MINIMUN").toString()) <= dto
                                                .getMontant().intValue()
                                                && Integer.parseInt(infoscommissionExceptionDetail.get("MAXIMUN")
                                                .toString()) >= dto.getMontant().intValue()) {
                                            commission = Double
                                                    .parseDouble(infoscommissionExceptionDetail.get("FRAIS").toString());
                                        }
                                    }
                                    break;
                                case 1:
                                    // Map<String, Object> infoscommissionDetailx = infoscommission.get(0);
                                    commission = Double.parseDouble(infoscommissionDetail.get("VALEUR").toString());
                                    break;
                                case 3:
                                    if (Utilities.isEmpty(infoscommission)) {
                                        response.setHasError(true);
                                        response.setStatus(functionalError
                                                .DISALLOWED_OPERATION("Impossible de calculer la commission", locale));
                                        return response;
                                    }
                                    // Map<String, Object> infoscommissionDetaily = infoscommission.get(0);
                                    commission = (double) Math.round(dto.getMontant().intValue()
                                            * Double.parseDouble(infoscommissionDetail.get("VALEUR").toString()) / 100);
                                    if (commission < Integer.parseInt(infoscommissionDetail.get("MNTLIM").toString()))
                                        commission = Double.parseDouble(infoscommissionDetail.get("MNTLIM").toString());
                                    break;
                            }
                        }
                    }
                }
                break;
        }

        dto.setCommission((double) commission);
        dto.setTimbre((double) timbre);
        response.setItem(dto);
        return response;
    }

    public Response<CommissionDto> verifMontantOperation(CommissionDto dto, Locale locale) {

        response = new Response<>();
        String exceptionValue = "A";
        String cptsur12 = "";
        String ncg = "";
        Integer check = 0;
        Integer verif = 0;
        String interdit = "O";
        String forfait = "S";
        List<Map<String, Object>> exceptionInfoList = null;
        List<Map<String, Object>> infosOperations = null;
        List<Map<String, Object>> infosOperationsx = null;

        // Si il s'agit d'un compte digital
        if (dto.getsOrig().equals("W")) {

            if (dto.getCompte().length() == 12)
                cptsur12 = dto.getCompte();
            else
                cptsur12 = Milieu(dto.getCompte(), 11, 12);
            WComptes existingEntity = wComptesRepository.findByNumeroComptecomplet(cptsur12);
            if (existingEntity != null) {
                ncg = existingEntity.getNgc();
            }
            // verifie si il y a exception sur le compte
            exceptionInfoList = wRetraitRepository.getTypeOperationException(dto.getCompteComplet(), dto.getCodeOp(),
                    dto.getCodeBq(), dto.getCodeOperationBq(), dto.getCodePack());
            if (Utilities.isNotEmpty(exceptionInfoList)) {
                exceptionValue = "X";
            }
            // si il s'agit d'un compte physique
        } else if (dto.getsOrig().equals("P")) {
            // si le compte n'est ni digital ni physique
        } else {
            response.setHasError(true);
            response.setStatus(functionalError.DISALLOWED_OPERATION("Type de compte non défini", locale));
            return response;
        }

        switch (exceptionValue) {
            // si le compte n'a pas d'exception
            case "A":
                Double cumulClient = 0.0;
                Integer nombreOperationClient = 0;

                if (dto.getsOrig().equals("W")) {
                    /**
                     * recupere les informations sur les operations déjà éffectuées sur le compte
                     **/
                    infosOperations = wRetraitRepository.getInfosOperations(dto.getCodePack(), dto.getCodeOp(),
                            dto.getCodeOperationBq(), dto.getCompteComplet());
                    if (Utilities.isEmpty(infosOperations)) {
                        cumulClient = Double.parseDouble(dto.getMontant().toString());
                        nombreOperationClient = 1;
                    }
                    /**                                          **/
                    else {
                        Map<String, Object> infosOperationsDetail = infosOperations.get(0);
                        cumulClient += Double.parseDouble(infosOperationsDetail.get("CUMUL_MNTNT").toString());
                        nombreOperationClient += Integer.parseInt(infosOperationsDetail.get("NBRE_OPER").toString());
                    }
                } else if (dto.getsOrig().equals("P")) {
                    infosOperations = wRetraitRepository.getInfosOperations(dto.getCodePack(), dto.getCodeOp(),
                            dto.getCodeOperationBq(), dto.getCompteComplet());
                    if (Utilities.isEmpty(infosOperations)) {
                        cumulClient = Double.parseDouble(dto.getMontant().toString());
                        nombreOperationClient = 1;
                    } else {
                        Map<String, Object> infosOperationsDetail = infosOperations.get(0);
                        cumulClient += Double.parseDouble(infosOperationsDetail.get("CUMUL_MNTNT").toString());

                        nombreOperationClient += Integer.parseInt(infosOperationsDetail.get("NBRE_OPER").toString());

                    }
                } else {
                    response.setHasError(true);
                    response.setStatus(functionalError.DISALLOWED_OPERATION("Type de compte non défini", locale));
                    return response;
                }
                // String ncg,String pack,String codeBanque,String codeOperation,String
                // codeOperationBq
                List<Map<String, Object>> normalInfos = wRetraitRepository.getNcgInfoByCompte(dto.getNcgcpt(),
                        dto.getCodePack(), dto.getCodeBq(), dto.getCodeOp(), dto.getCodeOperationBq());
                if (Utilities.isEmpty(normalInfos)) {
                    response.setHasError(true);
                    response.setStatus(
                            functionalError.DISALLOWED_OPERATION("Monant MIN et montant MAX non parametré", locale));
                    return response;
                }

                Map<String, Object> infosMontant = normalInfos.get(0);
                Double min = Double.parseDouble(infosMontant.get("MINMNT").toString());
                Double max = Double.parseDouble(infosMontant.get("MAXMNT").toString());
                Double cumul = Double.parseDouble(infosMontant.get("CUMULOPERPACK").toString());
                Double nombreOperations = Double.parseDouble(infosMontant.get("NBREOPERPACK").toString());
                Double cumulExit = Double.parseDouble(infosMontant.get("CUMULOPEREXIT").toString());
                Double nombreOperationsExit = Double.parseDouble(infosMontant.get("NBREOPEREXIT").toString());

                if (min > 0 && max > min) {
                    verif = 1;
                }
                if (min <= dto.getMontant().intValue() && max >= dto.getMontant().intValue()) {
                    check = 1;
                }
                if ((nombreOperationClient <= nombreOperations.intValue() && cumulClient >= cumul)
                        || (nombreOperationClient > nombreOperations.intValue() && cumulClient <= cumul)
                        || (nombreOperationClient > nombreOperations.intValue() && cumulClient < cumul)) {
                    forfait = "H";
                }
                if ((nombreOperationClient > nombreOperationsExit.intValue() && cumulClient >= cumulExit)
                        || (nombreOperationClient < nombreOperationsExit.intValue() && cumulClient >= cumulExit)
                        || (nombreOperationClient == nombreOperationsExit.intValue() && cumulClient > cumulExit)
                        || (nombreOperationClient > nombreOperationsExit.intValue() && cumulClient < cumulExit)) {
                    interdit = "I";
                    response.setHasError(true);
                    response.setStatus(functionalError.DISALLOWED_OPERATION("Opération interdite", locale));
                    return response;
                }
                break;
            // si le compte a une exception
            case "X":
                Double cumulClientx = 0.0;
                Integer nombreOperationClientx = 0;

                if (dto.getsOrig().equals("W")) {
                    /**
                     * recupere les informations sur les operations déjà éffectuées sur le compte
                     **/
                    infosOperationsx = wRetraitRepository.getInfosOperations(dto.getCodePack(), dto.getCodeOp(),
                            dto.getCodeOperationBq(), dto.getCompteComplet());
                    if (Utilities.isEmpty(infosOperationsx)) {
                        cumulClientx = Double.parseDouble(dto.getMontant().toString());
                        nombreOperationClientx = 1;
                    } else {
                        Map<String, Object> infosOperationsDetail = infosOperationsx.get(0);
                        cumulClientx += Double.parseDouble(infosOperationsDetail.get("CUMUL_MNTNT").toString());
                        nombreOperationClientx += Integer.parseInt(infosOperationsDetail.get("NBRE_OPER").toString());
                    }
                } else if (dto.getsOrig().equals("P")) {
                    Map<String, Object> infosOperationsDetail = infosOperationsx.get(0);
                    cumulClientx += Double.parseDouble(infosOperationsDetail.get("CUMUL_MNTNT").toString());
                    nombreOperationClientx += Integer.parseInt(infosOperationsDetail.get("NBRE_OPER").toString());
                } else {
                }

                Map<String, Object> infosExceptionDetail = exceptionInfoList.get(0);
                Double minx = Double.parseDouble(infosExceptionDetail.get("MINMNT").toString());
                Double maxs = Double.parseDouble(infosExceptionDetail.get("MAXMNT").toString());
                Double cumulx = Double.parseDouble(infosExceptionDetail.get("CUMULOPERPACK").toString());
                Double nombreOperationsx = Double.parseDouble(infosExceptionDetail.get("NBREOPERPACK").toString());
                Double cumulExitx = Double.parseDouble(infosExceptionDetail.get("CUMULOPEREXIT").toString());
                Double nombreOperationsExitx = Double.parseDouble(infosExceptionDetail.get("NBREOPEREXIT").toString());
                verif = 1;

                if (minx <= dto.getMontant().intValue() && maxs >= dto.getMontant().intValue()) {
                    check = 1;
                }
                if ((nombreOperationClientx > nombreOperationsExitx.intValue() && cumulClientx >= cumulExitx)
                        || (nombreOperationClientx < nombreOperationsExitx.intValue() && cumulClientx >= cumulExitx)
                        || (nombreOperationClientx == nombreOperationsExitx.intValue() && cumulClientx > cumulExitx)
                        || (nombreOperationClientx > nombreOperationsExitx.intValue() && cumulClientx < cumulExitx)) {
                    interdit = "I";
                    response.setHasError(true);
                    response.setStatus(functionalError.DISALLOWED_OPERATION("Opération interdite", locale));
                    return response;
                }

                if ((nombreOperationClientx <= nombreOperationsx.intValue() && cumulClientx > cumulx)
                        || (nombreOperationClientx > nombreOperationsx.intValue() && cumulClientx <= cumulx)
                        || (nombreOperationClientx > nombreOperationsx.intValue() && cumulClientx > cumulx)) {
                    forfait = "E";
                }
                break;
        }
        dto.setInterdit(interdit);
        dto.setForfait(forfait);
        response.setItem(dto);
        return response;
    }

    String Milieu(String compte, Integer debut, Integer fin) {
        return "";
    }

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> majSchemaComptableEtSolde(CommissionDto dto, Locale locale) {
        // String ref,String codeOper,String codeOperBq,String colR,String p_expl,String
        // p_agence,String p_banque,String p_caisse,String p_login,String p_cpt_reel
        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.schemaComptable(dto.getReferRenceOperation(), dto.getCodeOp(),
                dto.getCodeOperationBq(), NomColonneEnum.getLabel(dto.getCodeOp()), "", dto.getCodeAgence(),
                dto.getCodeBq(), dto.getCodeCaisse(), dto.getLogin(), "", dto.getMgrp());

        System.out.println("valeur de retour schema comptable" + valeurRetour);

        if (valeurRetour == null || valeurRetour.intValue() != 0) {
            response.setStatus(functionalError.CUSTOM("Impossible d'effectuer cette opération, contactez le service client", locale));
            //response.setStatus(functionalError.DISALLOWED_OPERATION("Impossible d'effectuer cette opération", locale));
            response.setHasError(true);
            return response;
        }

        System.out.println("valeur de retour schema comptable" + valeurRetour);
//		Integer majS = wTransfertRepository.majSolde(dto.getReferRenceOperation());
//		if(majS.equals(1)) {
//			response.setStatus(functionalError
//					.DISALLOWED_OPERATION(" erreur lors de la mise à jour des différents soldes ", locale));
//			response.setHasError(true);
//			return response;
//		}
        response.setItem(dto);
        return response;
    }
    @SuppressWarnings("unchecked")
    public Response<CommissionDto> majInitActeur(CommissionDto dto, Locale locale) {

        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.initacteur(dto.getCodeProd(), dto.getCodeOp(),
                dto.getCodeOperationBq(), dto.getLogin(), dto.getReferenceInit(), dto.getCompteComplet(),
                dto.getMontantComm());
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION(" erreur dans la fonction initiation acteur ", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    public Response<CommissionDto> initEmission(CommissionDto dto, Locale locale) {
        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.initemission(dto.getCodeBq(), dto.getCodeCaisse(),
                BigDecimal.valueOf(dto.getMontant()), dto.getCodeAgence(), dto.getLogin(),dto.getDateBordereau(),dto.getReferenceBordereau(),dto.getMotifBordereau(),dto.getCompte());
        if (valeurRetour == null || valeurRetour.intValue() != 0) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION("Erreur lors de l'initiation de l'émission", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    public Response<CommissionDto> f_init_distribuer(CommissionDto dto, Locale locale) {
        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.f_init_distribuer(dto.getCodeBq(), dto.getCodeCaisse(),
                BigDecimal.valueOf(dto.getMontant()),dto.getCompte(),dto.getCodeAgence(), dto.getLogin());
        if (valeurRetour == null || valeurRetour.intValue() != 0) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION("Erreur lors de l'initiation de la distribution", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    public Response<CommissionDto> f_valid_distribuer(CommissionDto dto, Locale locale) {
        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.f_valid_distribuer(dto.getReferenceInit(), dto.getCodeCaisse(), dto.getLogin());
        if (valeurRetour == null || valeurRetour.intValue() != 0) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION("Erreur lors de la validation de la distribution", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    public Response<CommissionDto> f_rejet_distribuer(CommissionDto dto, Locale locale) {
        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.f_rejet_distribuer(dto.getReferenceInit(), dto.getLogin());
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION("Erreur lors de la validation de la distribution", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    public Response<CommissionDto> validEmission(CommissionDto dto, Locale locale) {
        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.validemission(dto.getReferenceInit(), dto.getCodeCaisse(), dto.getLogin());
       // Integer valeurRetour = wRetraitRepository.validemission(dto.getReferenceInit(), dto.getCodeCaisse(), dto.getLogin());
        if (valeurRetour == null || valeurRetour.intValue() != 0) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION("Erreur lors de la validation de l'émission", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    public Response<CommissionDto> f_rejet_emission(CommissionDto dto, Locale locale) {
        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.f_rejet_emission(dto.getReferenceInit(), dto.getLogin());
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION("Erreur lors de la validation du rejet", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }


    @SuppressWarnings("unchecked")
    public Response<CommissionDto> annuleCollectedigital(CommissionDto dto, Locale locale) {

        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.annulerCollecte(dto.getLogin(), dto.getReferRenceOperation(), dto.getMotif(), dto.getCompte(), dto.getCodeAgence(), dto.getMontant().intValue());
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION(" erreur dans la fonction initiation acteur ", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    public Response<CommissionDto> creationAbonnements(CommissionDto dto, Locale locale) {

        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.creationAbonnements(dto.getCodeBq(), dto.getpProduit(), dto.getCodePack(), dto.getCodeClient(), dto.getCompteComplet(), dto.getMontant().intValue(), dto.getLogin());
        dto.setInterdit(valeurRetour.toString());
        response.setItem(dto);
        return response;
    }

    public Response<CommissionDto> existeAbonnements(CommissionDto dto, Locale locale) {

        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.existabonnement(dto.getCompteComplet());

        dto.setInterdit(valeurRetour.toString());
        response.setItem(dto);
        return response;
    }

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> compteAttenteOp(CommissionDto dto, Locale locale) {

        response = new Response<>();
        String valeurRetour = wRetraitRepository.compteAttenteOp(dto.getReferRenceOperation(), dto.getLogin(), dto.getMotif());
        if (valeurRetour == null || valeurRetour.contentEquals("")) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION(" erreur dans la fonction attente ", locale));
            response.setHasError(true);
            return response;
        }
        dto.setCompte(valeurRetour);
        response.setItem(dto);
        return response;
    }

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> annuleOper(CommissionDto dto, Locale locale) {

        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.annulOper(dto.getReferRenceOperation(), dto.getLogin(), dto.getMotif(), dto.getFichier(), dto.getCompte(), dto.getCodeAgence(), dto.getMontant().intValue());
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION(" erreur dans la fonction initiation acteur ", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> annuleOperC(CommissionDto dto, Locale locale) {

        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.annulOperC(dto.getReferRenceOperation(), dto.getLogin(), dto.getMotif(), dto.getFichier(), dto.getCompte(), dto.getCodeAgence(), dto.getMontant().intValue());
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION(" erreur dans la fonction initiation acteur ", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }


    public Response<CommissionDto> desactiverAbonnements(CommissionDto dto, Locale locale) {

        response = new Response<>();
        BigDecimal bigDecimal = new BigDecimal(dto.getCompte());
        Integer valeurRetour = wRetraitRepository.desactiverAbonnements(bigDecimal, dto.getLogin(),"");
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION(" erreur lors de la desactivation de l'abonnement", locale));
            response.setHasError(true);
            return response;
        }
        dto.setInterdit(valeurRetour.toString());
        response.setItem(dto);
        return response;
    }

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> extourneCollectedigital(CommissionDto dto, Locale locale) {

        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.extourneCollecte(dto.getLogin(), dto.getReferRenceOperation(), dto.getMotif(), dto.getCompte(), dto.getCodeAgence(), dto.getMontant().intValue());
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION(" erreur dans la fonction initiation acteur ", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> majPayActeur(CommissionDto dto, Locale locale) {

        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.payacteur(dto.getReferenceInit(), dto.getCodeOp(),
                dto.getCodeOperationBq(), dto.getLogin(), dto.getReferRenceOperation());
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION(" erreur dans la fonction initiation acteur ", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> majSolde(CommissionDto dto, Locale locale) {
        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.majSolde(dto.getReferRenceOperation());
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(functionalError.DISALLOWED_OPERATION(" erreur dans le schema comptable ", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> flaqrecouvre(CommissionDto dto, Locale locale) {
        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.flagrecouvre(dto.getPsite(), dto.getMontant().intValue(), dto.getPclient(), dto.getReferRenceOperation(), dto.getTaxeClient(), dto.getPtaxe());
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(functionalError.DISALLOWED_OPERATION(" erreur dans le flagrecouvre", locale));
            response.setHasError(true);
            return response;
        }
        response.setItem(dto);
        return response;
    }

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> codeClientFarFar(CommissionDto dto, Locale locale) {
        response = new Response<>();
        String chextrait[];
        String valeurRetour = wRetraitRepository.codeClient(dto.getCodeBq());
        // chaine.substring(10, 23) || valeurRetour.intValue() == 1;
        if (valeurRetour == null) {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION(" impossible de generer la sequence client ", locale));
            response.setHasError(true);
            return response;
        }
        chextrait = valeurRetour.split("##");
        if (chextrait[0] == "0") {
            response.setStatus(
                    functionalError.DISALLOWED_OPERATION(" erreur dans la generation de la sequence client ", locale));
            response.setHasError(true);
            return response;
        }
        dto.setCodeClient(chextrait[1].toString());
        response.setItem(dto);
        return response;
    }

    public BigDecimal getsequenceOuv(Integer ouv) {

        BigDecimal valeurRetour = null;

        switch (ouv) {

            case 1:
                valeurRetour = wRetraitRepository.seqCompte();
                break;

            case 2:
                valeurRetour = wRetraitRepository.seqInfoSup();
                break;

            case 3:
                valeurRetour = wRetraitRepository.seqgenerercarte();
                break;

            case 4:
                valeurRetour = wRetraitRepository.seqClientPin();
                break;
        }

        return valeurRetour;
    }

    @SuppressWarnings("unchecked")
    public Response<CommissionDto> annulerSchemaComptable(String referenceOperation, Locale locale) {
        response = new Response<>();
        Integer valeurRetour = wRetraitRepository.annulerSchemaComptable(referenceOperation);
        if (valeurRetour == null || valeurRetour.intValue() == 1) {
            response.setStatus(functionalError
                    .DISALLOWED_OPERATION(" erreur dans l'ors de l'annulation du schema comptable ", locale));
            response.setHasError(true);
            return response;
        }
        return response;
    }

    public Response<CommissionDto> rechercheMemeGroupe(CommissionDto dto, Locale locale) {
        response = new Response<>();
        System.out.println("========== SERVEUR [PK_BHMONEY.f_meme_groupe_cpt] ==========");
        System.out.println("  p1 = " + dto.getP1());
        System.out.println("  p2 = " + dto.getP2());
        System.out.println("====================================================");
        log.info("ACHT_TRACE [f_meme_groupe_cpt] p1={} p2={}", dto.getP1(), dto.getP2());
        String valeurRetour = wRetraitRepository.memeGroupe(dto.getP1(), dto.getP2());
        System.out.println("========== SERVEUR [PK_BHMONEY.f_meme_groupe_cpt RESPONSE] ==========");
        System.out.println("  p1   = " + dto.getP1());
        System.out.println("  p2   = " + dto.getP2());
        System.out.println("  mgrp = " + valeurRetour);
        System.out.println("====================================================");
        log.info("ACHT_TRACE [f_meme_groupe_cpt] p1={} p2={} mgrp={}", dto.getP1(), dto.getP2(), valeurRetour);
        if (valeurRetour == null) {
            response.setStatus(functionalError
                    .DISALLOWED_OPERATION(" erreur lors de la recherche du groupe", locale));
            response.setHasError(true);
            return response;
        }
        dto.setMgrp(valeurRetour);
        response.setItem(dto);
        return response;
    }


    private String calculReferenceOperation(String referenceOperation) {
        String carac = referenceOperation.substring(0, 1);
        int length = referenceOperation.length();
        Integer num = Integer.parseInt(referenceOperation.substring(1)) + 1;
        String forma = "%s%0" + (length - 1) + "d";
        String referOp = String.format(forma, carac, num);
        return referOp;
    }


    public boolean verifierChamp(String valeur) {
        // Expression régulière pour rechercher des lettres
        String regex = ".*[a-zA-Z].*";

        // Vérifier si la valeur correspond à la regex
        boolean contientLettres = valeur.matches(regex);

        // Retourner true si la valeur ne contient pas de lettres
        return !contientLettres;
    }

    public String genererchainealea() {
        String caracteres = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        StringBuilder sb = new StringBuilder(6);
        Random random = new Random();
        for (int i = 0; i < 6; i++) {
            int index = random.nextInt(caracteres.length());
            char caractere = caracteres.charAt(index);
            sb.append(caractere);
        }
        String chaine = sb.toString();
        System.out.println("Chaine générée : " + chaine);
        return chaine;
    }

    public String getReferenceOperationNum(String codeOperation, String codeBanque) {
        List<WReferenceOperation> refOperation = wReferenceOperationRepository.findByCodeOperation(codeOperation,
                codeBanque);
        if (refOperation == null || refOperation.isEmpty()) {
            List<WReferenceOperation> res = wReferenceOperationRepository.findLast();
            BigDecimal val = null;
            if (res == null || res.isEmpty()) {
                val = BigDecimal.valueOf(1);
            } else {
                val = res.get(0).getIdReferenceOperation().add(BigDecimal.valueOf(1));
            }
            WReferenceOperation wref = new WReferenceOperation();
            wref.setCodeOperation(codeOperation);
            wref.setCodeBanque(codeBanque);
            wref.setIdReferenceOperation(val);

            String referOp = codeOperation.substring(0, 1) + String.format("%015d", 1);
            wref.setNumOperation(referOp);
            WReferenceOperation wSave = wReferenceOperationRepository.save(wref);
            if (wSave == null) {
                return null;
            }
            return referOp;
        }
        WReferenceOperation wref = refOperation.get(0);
        String referenceOperation = wref.getNumOperation();
        String referOp = calculReferenceOperation(referenceOperation);
        wref.setNumOperation(referOp);
        WReferenceOperation wSave = wReferenceOperationRepository.save(wref);
        if (wSave == null) {
            return null;
        }
        return referOp;
    }

    public BigDecimal getNextSequence(String nomTable) {
        WSequence wSequence = wSequenceRepository.findByNomFichier(nomTable);
        if (wSequence == null) {
            return null;
        }
        BigDecimal currentId = wSequence.getIndiceSeq();
        if (currentId == null) {
            currentId = BigDecimal.ZERO;
        }
        currentId = currentId.add(BigDecimal.valueOf(1));
        // update value
        wSequence.setIndiceSeq(currentId);
        wSequenceRepository.save(wSequence);
        return currentId;
    }

    private String truncate(String value, int maxLength) {
        if (value == null) {
            return "";
        }
        return value.length() > maxLength ? value.substring(0, maxLength) : value;
    }

}
