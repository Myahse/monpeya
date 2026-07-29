package com.monpeya.backend.api.contracts;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonInclude.Include;

import jakarta.xml.bind.annotation.XmlRootElement;



@XmlRootElement
@JsonInclude(Include.NON_NULL)
public class Status {
	private String	code;
	private String	message;
	
	
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
	
	
	
}
