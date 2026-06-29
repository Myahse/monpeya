
/*
 * Created on 2019-10-16 ( Time 13:32:02 )
 * Generator tool : Telosys Tools Generator ( version 3.0.0 )
 * Copyright 2018 Geo. All Rights Reserved.
 */

package com.djogana.ticketing.api.contracts;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonInclude.Include;

import jakarta.xml.bind.annotation.XmlRootElement;
import java.util.List;
import java.util.Map;

/**
 * Response
 * 
 * @author Geo
 *
 */

@XmlRootElement
@JsonInclude(Include.NON_NULL)
public class Response<T> extends ResponseBase {

	protected List<T> items;
	protected  T item;
	protected String retourRequete;

	public String getRetourRequete() {
		return retourRequete;
	}

	public void setRetourRequete(String retourRequete) {
		this.retourRequete = retourRequete;
	}

	protected Map<String, Object[]> mapping;

	protected List<Map<String, Object>> mapList;

	public List<Map<String, Object>> getMapList() {
		return mapList;
	}

	public void setMapList(List<Map<String, Object>> mapList) {
		this.mapList = mapList;
	}

	protected Response<Map<String, Object>> mapObj;

	public Response<Map<String, Object>> getMapObj() {
		return mapObj;
	}

	public void setMapObj(Response<Map<String, Object>> mapObj) {
		this.mapObj = mapObj;
	}

	public Map<String, Object[]> getMapping() {
		return mapping;
	}

	public void setMapping(Map<String, Object[]> mapping) {
		this.mapping = mapping;
	}

	public List<T> getItems() {
		return items;
	}
	public void setItems(List<T> items) {
		this.items = items;
	}
	public T getItem() {
		return item;
	}
	public void setItem(T item) {
		this.item = item;
	}
	
	
	
}
