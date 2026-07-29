


package com.monpeya.backend.api.contracts;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonInclude.Include;

import jakarta.xml.bind.annotation.XmlRootElement;
import java.util.List;

/**
 * Request
 * 
 * @author Geo
 *
 */
@XmlRootElement
@JsonInclude(Include.NON_NULL)
public class Request<T> extends RequestBase {
	private Integer page;
	private Integer size;
	protected T			data;
	protected List<T>	datas;
	public T getData() {
		return data;
	}
	public void setData(T data) {
		this.data = data;
	}
	public List<T> getDatas() {
		return datas;
	}
	public void setDatas(List<T> datas) {
		this.datas = datas;
	}

	public Integer getPage() {
		return page;
	}

	public void setPage(Integer page) {
		this.page = page;
	}

	public Integer getSize() {
		return size;
	}

	public void setSize(Integer size) {
		this.size = size;
	}
}