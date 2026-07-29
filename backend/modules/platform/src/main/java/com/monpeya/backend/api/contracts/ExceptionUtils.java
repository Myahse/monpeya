

package com.monpeya.backend.api.contracts;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Locale;

import com.monpeya.backend.api.service.FunctionalRollbackException;

@Component
public class ExceptionUtils {

	private static Logger	slf4jLogger;

	/*
	 * @Autowired private FunctionalError functionalError;
	 */

	@Autowired
	private TechnicalError	technicalError;

	public ExceptionUtils() {
		slf4jLogger = LoggerFactory.getLogger(getClass());
	}

	/**
	 * Permission non accordée pour acceder au serveur de BD
	 * 
	 * @param response
	 * @param locale
	 * @param e
	 */
	public void PERMISSION_DENIED_DATA_ACCESS_EXCEPTION(ResponseBase response, Locale locale, Exception e) {
		// Permission non accordée pour acceder au serveur de BD
		e.printStackTrace();
		response.setHasError(Boolean.TRUE);
		response.setStatus(technicalError.DB_PERMISSION_DENIED(e.getMessage(), locale));
		slf4jLogger.warn("Erreur| code: {} -  message: {} - cause: {}  - SysMessage: {}", StatusCode.TECH_DB_PERMISSION_DENIED, StatusMessage.TECH_DB_PERMISSION_DENIED, e.getCause(), e.getMessage());
	}

	/**
	 * Base de données indisponible
	 * 
	 * @param response
	 * @param locale
	 * @param e
	 */
	public void DATA_ACCESS_RESOURCE_FAILURE_EXCEPTION(ResponseBase response, Locale locale, Exception e) {
		// base de données indisponible
		e.printStackTrace();
		response.setHasError(Boolean.TRUE);
		response.setStatus(technicalError.DB_FAIL(e.getMessage(), locale));
		slf4jLogger.warn("Erreur| code: {} -  message: {} - cause: {}  - SysMessage: {}", StatusCode.TECH_DB_FAIL, StatusMessage.TECH_DB_FAIL, e.getCause(), e.getMessage());
	}

	/**
	 * Serveur a refusé la requete
	 * 
	 * @param response
	 * @param locale
	 * @param e
	 */
	public void DATA_ACCESS_EXCEPTION(ResponseBase response, Locale locale, Exception e) {
		// Serveur a refusé la requete
		e.printStackTrace();
		response.setHasError(Boolean.TRUE);
		response.setStatus(technicalError.DB_QUERY_REFUSED(e.getMessage(), locale));
		slf4jLogger.warn("Erreur| code: {} -  message: {} - cause: {}  - SysMessage: {}", StatusCode.TECH_DB_QUERY_REFUSED, StatusMessage.TECH_DB_QUERY_REFUSED, e.getCause(), e.getMessage());
	}

	/**
	 * Erreur interne
	 * 
	 * @param response
	 * @param locale
	 * @param e
	 */
	public void RUNTIME_EXCEPTION(ResponseBase response, Locale locale, Exception e) {
		if (response == null || e == null) {
			return;
		}
		try {
			FunctionalRollbackException fre = findFunctionalRollback(e);
			if (fre != null && fre.getResponse() != null) {
				ResponseBase embedded = fre.getResponse();
				response.setHasError(embedded.isHasError());
				response.setStatus(embedded.getStatus());
				response.setSessionUser(embedded.getSessionUser());
				response.setCount(embedded.getCount());
				response.setTokenCnam(embedded.getTokenCnam());
				response.setTokennmpf(embedded.getTokennmpf());
				return;
			}
			e.printStackTrace();
			try {
				slf4jLogger.error("Unhandled runtime exception (root={})", rootCauseSummary(e), e);
			} catch (Exception ignored) {
			}
			response.setHasError(Boolean.TRUE);
			String root = rootCauseSummary(e);
			response.setStatus(technicalError.ERROR(root, locale));
			Status st = response.getStatus();
			if (st != null) {
				slf4jLogger.warn("Erreur| code: {} -  message: {} - cause: {}  - SysMessage: {}", st.getCode(),
						StatusMessage.FUNC_FAIL, e.getCause(), st.getMessage());
			}
		} catch (Throwable handlerFailure) {
			slf4jLogger.error("ExceptionUtils.RUNTIME_EXCEPTION failed while handling {}", e.getClass().getName(),
					handlerFailure);
			response.setHasError(Boolean.TRUE);
			Status fallback = new Status();
			fallback.setCode(StatusCode.FUNC_FAIL);
			String msg = rootCauseSummary(e);
			fallback.setMessage(msg != null && !msg.isEmpty() ? msg : e.getClass().getName());
			response.setStatus(fallback);
		}
	}

	/**
	 * Erreur interne
	 * 
	 * @param response
	 * @param locale
	 * @param e
	 */
	public void EXCEPTION(ResponseBase response, Locale locale, Exception e) {
		if (response == null || e == null) {
			return;
		}
		FunctionalRollbackException fre = findFunctionalRollback(e);
		if (fre != null && fre.getResponse() != null) {
			ResponseBase embedded = fre.getResponse();
			response.setHasError(embedded.isHasError());
			response.setStatus(embedded.getStatus());
			response.setSessionUser(embedded.getSessionUser());
			response.setCount(embedded.getCount());
			response.setTokenCnam(embedded.getTokenCnam());
			response.setTokennmpf(embedded.getTokennmpf());
			return;
		}
		// Erreur interne
		e.printStackTrace();
		try {
			slf4jLogger.error("Unhandled exception (root={})", rootCauseSummary(e), e);
		} catch (Exception ignored) {
		}
		response.setHasError(Boolean.TRUE);
		String root = rootCauseSummary(e);
		response.setStatus(technicalError.INTERN_ERROR(root, locale));
		slf4jLogger.warn("Erreur| code: {} -  message: {} - cause: {}  - SysMessage: {}", StatusCode.TECH_INTERN_ERROR, StatusMessage.TECH_INTERN_ERROR, e.getCause(), root);
		e.printStackTrace();
		// e.getStackTrace();
	}

	private static FunctionalRollbackException findFunctionalRollback(Throwable t) {
		Throwable cur = t;
		int guard = 0;
		while (cur != null && guard++ < 20) {
			if (cur instanceof FunctionalRollbackException fre) {
				return fre;
			}
			Throwable cause = cur.getCause();
			if (cause == cur) {
				break;
			}
			cur = cause;
		}
		return null;
	}

	private static String rootCauseSummary(Throwable t) {
		if (t == null) {
			return null;
		}
		Throwable root = t;
		int guard = 0;
		while (root.getCause() != null && root.getCause() != root && guard++ < 20) {
			root = root.getCause();
		}
		String rootMsg = root.getMessage();
		String topMsg = t.getMessage();
		String rootClass = root.getClass().getSimpleName();
		if (rootMsg != null && !rootMsg.isBlank()) {
			return rootClass + ": " + rootMsg;
		}
		if (topMsg != null && !topMsg.isBlank()) {
			return t.getClass().getSimpleName() + ": " + topMsg;
		}
		return t.getClass().getName();
	}

	/**
	 * 
	 * @param response
	 * @param locale
	 * @param e
	 */
	public void CANNOT_CREATE_TRANSACTION_EXCEPTION(ResponseBase response, Locale locale, Exception e) {
		// Impossible de se connecter à  la base de données
		e.printStackTrace();
		response.setHasError(Boolean.TRUE);
		response.setStatus(technicalError.DB_NOT_CONNECT(e.getMessage(), locale));
		slf4jLogger.warn("Erreur| code: {} -  message: {} - cause: {}  - SysMessage: {}", StatusCode.TECH_DB_NOT_CONNECT, StatusMessage.TECH_DB_NOT_CONNECT, e.getCause(), e.getMessage());
	}

	/**
	 * 
	 * @param response
	 * @param locale
	 * @param e
	 */
	public void TRANSACTION_SYSTEM_EXCEPTION(ResponseBase response, Locale locale, Exception e) {
		// base de données indisponible
		e.printStackTrace();
		response.setHasError(Boolean.TRUE);
		response.setStatus(technicalError.DB_FAIL(e.getMessage(), locale));
		slf4jLogger.warn("Erreur| code: {} -  message: {} - cause: {}  - SysMessage: {}", StatusCode.TECH_DB_FAIL, StatusMessage.TECH_DB_FAIL, e.getCause(), e.getMessage());
	}
}