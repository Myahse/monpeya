
/*
 * Created on 2019-10-16 ( Time 13:32:02 )
 * Generator tool : Telosys Tools Generator ( version 3.0.0 )
 * Copyright 2018 Geo. All Rights Reserved.
 */

package com.djogana.ticketing.api.contracts;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.MessageSource;
import org.springframework.stereotype.Component;

import jakarta.xml.bind.annotation.XmlRootElement;
import java.util.Locale;

/**
 * Technical Error
 * 
 * @author Geo
 *
 */

@XmlRootElement
@Component
public class TechnicalError {

	private String			code;
	private String			message;
	@Autowired
	private MessageSource	messageSource;
	
	private static Status	status	= new Status();
		
	

	public String getCode() {
		return code;
	}

	public void setCode(String code) {
		this.code = code;
	}

	public String getMessage() {
		return message;
	}

	public void setMessage(String message) {
		this.message = message;
	}

	public Status DB_NOT_CONNECT(String message, Locale locale) {
		status.setCode(StatusCode.TECH_DB_NOT_CONNECT);
		status.setMessage(messageSource.getMessage("StatusMessage.TECH_DB_NOT_CONNECT", new Object[] {}, locale) + ": " + message);
		return status;
	}

	public Status DB_FAIL(String message, Locale locale) {
		status.setCode(StatusCode.TECH_DB_FAIL);
		status.setMessage(messageSource.getMessage("StatusMessage.TECH_DB_FAIL", new Object[] {}, locale) + ": " + message);
		return status;
	}

	public Status INTERN_ERROR(String message, Locale locale) {
		status.setCode(StatusCode.TECH_INTERN_ERROR);
		String msg = messageSource.getMessage("StatusMessage.TECH_INTERN_ERROR", new Object[] {}, locale);
		status.setMessage(msg + ": " + message);
		return status;
	}

	public Status DB_PERMISSION_DENIED(String message, Locale locale) {
		status.setCode(StatusCode.TECH_DB_PERMISSION_DENIED);
		status.setMessage(messageSource.getMessage("StatusMessage.TECH_DB_PERMISSION_DENIED", new Object[] {}, locale) + ": " + message);
		return status;
	}

	public Status DB_QUERY_REFUSED(String message, Locale locale) {
		status.setCode(StatusCode.TECH_DB_QUERY_REFUSED);
		status.setMessage(messageSource.getMessage("StatusMessage.TECH_DB_QUERY_REFUSED", new Object[] {}, locale) + ": " + message);
		return status;
	}

	public Status ERROR(String message, Locale locale) {
		String safe = message != null ? message : "";
		String[] msgTab = safe.split(";", -1);
		if (msgTab.length > 1) {
			status.setCode(msgTab[0]);
			status.setMessage(msgTab[1]);
		} else {
			status.setCode(StatusCode.FUNC_FAIL);
			status.setMessage(safe.isEmpty() ? StatusMessage.FUNC_FAIL : safe);
		}
		return status;
	}
}
