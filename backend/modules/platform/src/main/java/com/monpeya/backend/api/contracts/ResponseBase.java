
/*
 * Created on 2019-10-16 ( Time 13:32:02 )
 * Generator tool : Telosys Tools Generator ( version 3.0.0 )
 * Copyright 2018 Geo. All Rights Reserved.
 */

package com.monpeya.backend.api.contracts;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonInclude.Include;

/**
 * Response Base
 * 
 * @author Geo
 *
 */
@JsonInclude(Include.NON_NULL)
public class ResponseBase {

	protected Status status = new Status();
	protected boolean hasError;
	protected String sessionUser;
	protected Long count;
	protected String tokenCnam;

	protected String tokennmpf;

	public String getTokennmpf() {
		return tokennmpf;
	}

	public void setTokennmpf(String tokennmpf) {
		this.tokennmpf = tokennmpf;
	}

	public Status getStatus() {
		return status;
	}

	public void setStatus(Status status) {
		this.status = status;
	}

	public boolean isHasError() {
		return hasError;
	}

	public void setHasError(boolean hasError) {
		this.hasError = hasError;
	}

	public String getSessionUser() {
		return sessionUser;
	}

	public void setSessionUser(String sessionUser) {
		this.sessionUser = sessionUser;
	}

	public Long getCount() {
		return count;
	}

	public void setCount(Long count) {
		this.count = count;
	}

	public String getTokenCnam() {
		return tokenCnam;
	}

	public void setTokenCnam(String tokenCnam) {
		this.tokenCnam = tokenCnam;
	}

}
