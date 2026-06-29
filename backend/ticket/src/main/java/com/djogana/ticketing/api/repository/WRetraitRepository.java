package com.djogana.ticketing.api.repository;

import com.djogana.ticketing.api.dto.WRetraitDto;
import com.djogana.ticketing.api.entity.WRetrait;
import jakarta.persistence.EntityManager;
import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Repository
public interface WRetraitRepository extends JpaRepository<WRetrait, String> {

    @Query("select e from WRetrait e where e.numretrait = :numretrait")
    WRetrait findByCoderetrait(@Param("numretrait") String numretrait);

    @Query(value = "select * from W_TYPEOPERATION_W_CPT_EX where compte= :compte AND CODEOPERATION = :codeOp AND CODE_BANQUE = :codeB AND CODEOPERATIONBQ = :codeOpBq AND code_pack= :pack", nativeQuery = true)
    List<Map<String, Object>> getTypeOperationException(@Param("compte") String compte, @Param("codeOp") String codeOp,
                                                        @Param("codeB") String codeB, @Param("codeOpBq") String codeOpBq, @Param("pack") String pack);


    @Query(value = "select numerocomptecomplet from w_comptes where ngc like :ngc AND code_client = :code_client", nativeQuery = true)
    String getCompteCommission(@Param("ngc") String ngc, @Param("code_client") String code_client);

    @Query(value = "SELECT * FROM W_TYPEOPERATION_W_NCG " + "WHERE W_TYPEOPERATION_W_NCG.Code_Banque= :codeBanque AND "
            + "W_TYPEOPERATION_W_NCG.NGC= :ncg AND " + "W_TYPEOPERATION_W_NCG.CodeOperation= :codeOperation AND "
            + "W_TYPEOPERATION_W_NCG.CodeoperationBq=:codeOperationBq AND "
            + "W_TYPEOPERATION_W_NCG.CODE_PACK= :pack ", nativeQuery = true)
    List<Map<String, Object>> getNcgInfoByCompte(@Param("ncg") String ncg, @Param("pack") String pack,
                                                 @Param("codeBanque") String codeBanque, @Param("codeOperation") String codeOperation,
                                                 @Param("codeOperationBq") String codeOperationBq);

    @Query(value = "select * from W_PARAMETRE where CPACK_NCG_COP_BQ_COPBQ_CRITERE= :codeTypeTimbre", nativeQuery = true)
    List<Map<String, Object>> getInfosTimbre(@Param("codeTypeTimbre") String codeTypeTimbre);

    @Query(value = "select * from W_REFERENCE_OPERATION where CODEOPERATION= :codeOper", nativeQuery = true)
    List<Map<String, Object>> getReference(@Param("codeOper") String codeOper);

    @Query(value = "select * from W_PARAMETRE where CPACK_NCG_COP_BQ_COPBQ_CRITERE= :codeTypeCommission", nativeQuery = true)
    List<Map<String, Object>> getInfosCommission(@Param("codeTypeCommission") String codeTypeCommission);

    @Query(value = "select * from W_PALLIER where CPACK_CODECOMPLET= :codeTypeTimbre1 AND CRITERE_F= :criteref", nativeQuery = true)
    List<Map<String, Object>> getInfosTimbreException(@Param("codeTypeTimbre1") String codeTypeTimbre1,
                                                      @Param("criteref") String criteref);

    @Query(value = "select * from W_PALLIER where CPACK_CODECOMPLET= :codeTypeCommission1 AND CRITERE_F= :criteref", nativeQuery = true)
    List<Map<String, Object>> getInfosCommissionException(@Param("codeTypeCommission1") String codeTypeCommission1,
                                                          @Param("criteref") String criteref);

    @Query(value = "select * from W_CPT_NB_OPERATION where compte = :compte AND code_pack = :pack", nativeQuery = true)
    List<Map<String, Object>> getNbOperationByCompte(@Param("compte") String compte, @Param("pack") String pack);

    @Query(value = "select * from W_REFERENCE_OPERATION where CODEOPERATION= :codeOp", nativeQuery = true)
    List<Map<String, Object>> recupererReference(@Param("codeOp") String codeOp);

    @Query(value = "select * from W_CPT_NB_OPERATION where code_pack= :pack AND code_oper= :codeOp AND code_operbq= :codeOpBq AND compte= :compte", nativeQuery = true)
    List<Map<String, Object>> getInfosOperations(@Param("pack") String pack, @Param("codeOp") String codeOp,
                                                 @Param("codeOpBq") String codeOpBq, @Param("compte") String compte);

    @Query(value = "SELECT PK_BHMONEY.VERIF_SOLDE(:compte,:montant) FROM DUAL", nativeQuery = true)
    Integer verifSolde(@Param("compte") String compte, @Param("montant") String montant);

    @Query(value = "SELECT PK_BHMONEY.VERIF_SOLDE_WB(:compte,:montant) FROM DUAL", nativeQuery = true)
    Integer verifSoldeWb(@Param("compte") String compte, @Param("montant") String montant);

    @Query(value = "SELECT PK_BHMONEY.f_schema_comptable(:ref,:codeOper,:codeOperBq,:colR,:p_expl,:p_agence,:p_banque,:p_caisse,:p_login,:p_cpt_reel,:p_mgrp) FROM DUAL", nativeQuery = true)
    Integer schemaComptable(@Param("ref") String ref, @Param("codeOper") String codeOper,
                            @Param("codeOperBq") String codeOperBq, @Param("colR") String colR, @Param("p_expl") String p_expl,
                            @Param("p_agence") String p_agence, @Param("p_banque") String p_banque, @Param("p_caisse") String p_caisse,
                            @Param("p_login") String p_login, @Param("p_cpt_reel") String p_cpt_reel,@Param("p_mgrp") String p_mgrp);

    @Query(value = "SELECT pk_digital_tax.f_flag_recouv(:psite,:pmontant,:pclient,:prefer,:ptaxe,:ptax) FROM DUAL", nativeQuery = true)
    Integer flagrecouvre(@Param("psite") String psite, @Param("pmontant") Integer pmontant,@Param("pclient") String pclient,
                         @Param("prefer") String prefer, @Param("ptaxe") String ptaxe, @Param("ptax") String ptax);


    @Query(value = "SELECT PK_BHMONEY.ANNUL_OPER(:ref) FROM DUAL", nativeQuery = true)
    Integer annulerSchemaComptable(@Param("ref") String ref);

    @Query(value = "SELECT pk_pack.f_creer_abon(:p_bq,:p_produit,:p_pack,:p_client,:p_compte,:p_montant,:p_login) FROM DUAL", nativeQuery = true)
    Integer creationAbonnements(@Param("p_bq") String p_bq,@Param("p_produit") String p_produit,@Param("p_pack") String p_pack,@Param("p_client") String p_client,@Param("p_compte") String p_compte,@Param("p_montant") Integer p_montant,@Param("p_login") String p_login);

    @Query(value = "SELECT pk_pack.f_desactive_abon(:p_id,:p_login,:p_motif) FROM DUAL", nativeQuery = true)
    Integer desactiverAbonnements(@Param("p_id") BigDecimal p_id, @Param("p_login") String p_login, @Param("p_motif") String p_motif);

    @Query(value = "SELECT PK_BHMONEY.f_cpt_att_retrait(:p_num_retrait,:p_login,:p_motif_retrait) FROM DUAL", nativeQuery = true)
    String compteAttenteOp(@Param("p_num_retrait") String p_num_retrait,@Param("p_login") String p_login,@Param("p_motif_retrait") String p_motif_retrait);

    @Query(value = "SELECT PK_DIGITAL_TAX.F_ANNUL_COLLECTE(:p_login,:ref,:p_motif,:p_log_pr_annul,:p_agence,:p_montant) FROM DUAL", nativeQuery = true)
    Integer annulerCollecte(@Param("p_login") String p_login,@Param("ref") String ref,@Param("p_motif") String p_motif,@Param("p_log_pr_annul") String p_log_pr_annul,@Param("p_agence") String p_agence,@Param("p_montant") Integer p_montant);

    @Query(value = "SELECT pk_bhmoney.annul_oper(:VNOOPER,:p_login,:motif,:p_fichier,:p_log_pr_annul,:p_agence,:p_montant) FROM DUAL", nativeQuery = true)
    Integer annulOper(@Param("VNOOPER") String VNOOPER,@Param("p_login") String p_login,@Param("motif") String motif,@Param("p_fichier") String p_fichier,@Param("p_log_pr_annul") String p_log_pr_annul,@Param("p_agence") String p_agence,@Param("p_montant") Integer p_montant);

    @Query(value = "SELECT pk_bhmoney.annul_oper_c(:VNOOPER,:p_login,:motif,:p_fichier,:p_log_pr_annul,:p_agence,:p_montant) FROM DUAL", nativeQuery = true)
    Integer annulOperC(@Param("VNOOPER") String VNOOPER,@Param("p_login") String p_login,@Param("motif") String motif,@Param("p_fichier") String p_fichier,@Param("p_log_pr_annul") String p_log_pr_annul,@Param("p_agence") String p_agence,@Param("p_montant") Integer p_montant);

    @Query(value = "SELECT PK_DIGITAL_TAX.F_ANNUL_COLLECTE_C(:p_login,:ref,:p_motif,:p_log_pr_annul,:p_agence,:p_montant) FROM DUAL", nativeQuery = true)
    Integer extourneCollecte(@Param("p_login") String p_login,@Param("ref") String ref,@Param("p_motif") String p_motif,@Param("p_log_pr_annul") String p_log_pr_annul,@Param("p_agence") String p_agence,@Param("p_montant") Integer p_montant);

    @Query(value = "SELECT PK_BHMONEY.F_SEQ_CLIENT(:codbq) FROM DUAL", nativeQuery = true)
    String codeClient(@Param("codbq") String codbq);

    @Query(value = "SELECT PK_BHMONEY.f_seq_comptes() FROM DUAL", nativeQuery = true)
    BigDecimal seqCompte();

    @Query(value = "SELECT PK_BHMONEY.f_seq_infosup() FROM DUAL", nativeQuery = true)
    BigDecimal seqInfoSup();

    @Query(value = "SELECT PK_BHMONEY.f_seq_generercarte() FROM DUAL", nativeQuery = true)
    BigDecimal seqgenerercarte();

    @Query(value = "SELECT PK_BHMONEY.f_seq_clientspin() FROM DUAL", nativeQuery = true)
    BigDecimal seqClientPin();

    @Query(value = "SELECT PK_BHMONEY.f_meme_groupe_cpt(:p1,:p2) FROM DUAL", nativeQuery = true)
    String memeGroupe(@Param("p1") String p1,@Param("p2") String p2);

    @Query(value = "SELECT pk_pack.f_existe_abon(:p_compte) FROM DUAL", nativeQuery = true)
    Integer existabonnement(@Param("p_compte") String p_compte);

    @Query(value = "SELECT PK_BHMONEY.psldisp(:reference) FROM DUAL", nativeQuery = true)
    Integer majSolde(@Param("reference") String reference);

    @Query(value = "SELECT PK_COMP_FARFAR.f_ini_w_acteur(:p_prod,:p_oper_ini,:p_operbq_ini,:p_login,:p_ref_ini,:p_cpt_clt,:p_mnt_com) FROM DUAL", nativeQuery = true)
    Integer initacteur(@Param("p_prod") String p_prod, @Param("p_oper_ini") String p_oper_ini,
                       @Param("p_operbq_ini") String p_operbq_ini, @Param("p_login") String p_login,
                       @Param("p_ref_ini") String p_ref_ini, @Param("p_cpt_clt") String p_cpt_clt,
                       @Param("p_mnt_com") Integer p_mnt_com);

    @Query(value = "SELECT pk_peya.f_init_emission(:p_banque,:p_caisse,:p_montant,:p_agence,:p_login,:date_depot,:ref_depot,:motif_depot,:p_cpt_credit) FROM DUAL", nativeQuery = true)
    Integer initemission(@Param("p_banque") String p_banque, @Param("p_caisse") String p_caisse,
                       @Param("p_montant") BigDecimal p_montant, @Param("p_agence") String p_agence,
                       @Param("p_login") String p_login,@Param("date_depot") String date_depot,@Param("ref_depot") String ref_depot, @Param("motif_depot") String motif_depot,@Param("p_cpt_credit") String p_cpt_credit);

    @Query(value = "SELECT pk_peya.f_init_distribuer(:p_banque,:p_caisse,:p_montant,:p_cpt_credit,:p_agence,:p_login) FROM DUAL", nativeQuery = true)
    Integer f_init_distribuer(@Param("p_banque") String p_banque, @Param("p_caisse") String p_caisse,
                         @Param("p_montant") BigDecimal p_montant, @Param("p_cpt_credit") String p_cpt_credit,
                         @Param("p_agence") String p_agence,@Param("p_login") String p_login);

    @Query(value = "SELECT pk_peya.f_valid_distribuer(:p_ref,:p_caisse,:p_login) FROM DUAL", nativeQuery = true)
    Integer f_valid_distribuer(@Param("p_ref") String p_ref, @Param("p_caisse") String p_caisse,@Param("p_login") String p_login);

    @Query(value = "SELECT pk_peya.f_rejet_distribuer(:p_ref,:p_login) FROM DUAL", nativeQuery = true)
    Integer f_rejet_distribuer(@Param("p_ref") String p_ref,@Param("p_login") String p_login);


    @Query(value = "SELECT pk_peya.f_valid_emission(:p_ref,:p_caisse,:p_login) FROM DUAL", nativeQuery = true)
    Integer validemission(@Param("p_ref") String p_ref, @Param("p_caisse") String p_caisse,
                         @Param("p_login") String p_login);

    @Query(value = "SELECT pk_peya.f_rejet_emission(:p_ref,:p_login) FROM DUAL", nativeQuery = true)
    Integer f_rejet_emission(@Param("p_ref") String p_banque,@Param("p_login") String p_login);

    @Query(value = "SELECT PK_COMP_FARFAR.f_pay_w_acteur(:p_oper_ini,:p_oper_pay,:p_operbq_pay,:p_login,:p_ref_pay) FROM DUAL", nativeQuery = true)
    Integer payacteur(@Param("p_oper_ini") String p_oper_ini, @Param("p_oper_pay") String p_oper_pay,
                      @Param("p_operbq_pay") String p_operbq_pay, @Param("p_login") String p_login,
                      @Param("p_ref_pay") String p_ref_pay);

    @Query(value = "SELECT pk_digital_tax.f_temps_station(:p_oper_ini) FROM DUAL", nativeQuery = true)
    Integer tempstation(@Param("p_oper_ini") String p_oper_ini);

    @Query(value = "SELECT pk_digital_tax.f_maj_station(:p_oper_ini, :p1) FROM DUAL", nativeQuery = true)
    BigDecimal majstation(@Param("p_oper_ini") String p_oper_ini,@Param("p1") BigDecimal p1);


    default String schemaComptableMaj(EntityManager em, String ref, String codeOper, String codeOperBq, String colR,
                                      String p_expl, String p_agence, String p_banque, String p_caisse, String p_login, String p_cpt_reel,
                                      Locale locale) {

        StoredProcedureQuery storedProcedure = em.createStoredProcedureQuery("PK_BHMONEY.f_schema_comptable");

        // Set the parameters of the stored procedure.

        storedProcedure.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);
        storedProcedure.registerStoredProcedureParameter(2, String.class, ParameterMode.IN);
        storedProcedure.registerStoredProcedureParameter(3, String.class, ParameterMode.IN);
        storedProcedure.registerStoredProcedureParameter(4, String.class, ParameterMode.IN);
        storedProcedure.registerStoredProcedureParameter(5, String.class, ParameterMode.IN);
        storedProcedure.registerStoredProcedureParameter(6, String.class, ParameterMode.IN);
        storedProcedure.registerStoredProcedureParameter(7, String.class, ParameterMode.IN);
        storedProcedure.registerStoredProcedureParameter(8, String.class, ParameterMode.IN);
        storedProcedure.registerStoredProcedureParameter(9, String.class, ParameterMode.IN);
        storedProcedure.registerStoredProcedureParameter(10, String.class, ParameterMode.IN);

        storedProcedure.setParameter(1, ref);
        storedProcedure.setParameter(2, codeOper);
        storedProcedure.setParameter(3, codeOperBq);
        storedProcedure.setParameter(4, colR);
        storedProcedure.setParameter(5, p_expl);
        storedProcedure.setParameter(6, p_agence);
        storedProcedure.setParameter(7, p_banque);
        storedProcedure.setParameter(8, p_caisse);
        storedProcedure.setParameter(9, p_login);
        storedProcedure.setParameter(10, p_cpt_reel);

        Object storedProcedureResult = storedProcedure.getSingleResult();

        return storedProcedureResult.toString();
    }

    default String majSolde(WRetraitDto dto, EntityManager em, Locale locale) {
        StoredProcedureQuery storedProcedure = em.createStoredProcedureQuery("psldisp");

        // Set the parameters of the stored procedure.
        String firstParam = "Vnooper";
        storedProcedure.registerStoredProcedureParameter(firstParam, String.class, ParameterMode.IN);
        storedProcedure.setParameter(firstParam, firstParam);
        // Call the stored procedure.
        Object storedProcedureResult = storedProcedure.getSingleResult();

        return storedProcedureResult.toString();
    }


}
