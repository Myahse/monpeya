

package com.monpeya.backend.api.contracts;

/**
 * Request Base
 * 
 * @author Geo
 *
 */

public class RequestBase {
	protected String		sessionUser;
	protected Integer		size;
	protected Integer		index;
	protected String		lang;
	protected String		businessLineCode;
	protected String		caseEngine;
	protected Boolean		isAnd;
	protected Integer		user;
	protected Boolean 		isSimpleLoading;
	protected Boolean   	isDashboard;
	protected Boolean 		isHour;
	protected Boolean 		isDay;
	protected Boolean 		isMonth;
	protected Boolean 		isYear;
	protected Boolean       isFormating;
	protected Boolean       withInfo;
	private String groupeMobile;
	protected Boolean isForGraph;
	private String start;
	private String end;
	

	protected String		userLogin;
	
	
	public String getSessionUser() {
		return sessionUser;
	}
	public void setSessionUser(String sessionUser) {
		this.sessionUser = sessionUser;
	}
	public Integer getSize() {
		return size;
	}
	public void setSize(Integer size) {
		this.size = size;
	}
	public Integer getIndex() {
		return index;
	}
	public void setIndex(Integer index) {
		this.index = index;
	}
	public String getLang() {
		return lang;
	}
	public void setLang(String lang) {
		this.lang = lang;
	}
	public String getBusinessLineCode() {
		return businessLineCode;
	}
	public void setBusinessLineCode(String businessLineCode) {
		this.businessLineCode = businessLineCode;
	}
	public String getCaseEngine() {
		return caseEngine;
	}
	public void setCaseEngine(String caseEngine) {
		this.caseEngine = caseEngine;
	}
	public Boolean getIsAnd() {
		return isAnd;
	}
	public void setIsAnd(Boolean isAnd) {
		this.isAnd = isAnd;
	}
	public Integer getUser() {
		return user;
	}
	public void setUser(Integer user) {
		this.user = user;
	}
	public Boolean getIsSimpleLoading() {
		return isSimpleLoading;
	}
	public void setIsSimpleLoading(Boolean isSimpleLoading) {
		this.isSimpleLoading = isSimpleLoading;
	}
	public Boolean getIsDashboard() {
		return isDashboard;
	}
	public void setIsDashboard(Boolean isDashboard) {
		this.isDashboard = isDashboard;
	}
	public Boolean getIsHour() {
		return isHour;
	}
	public void setIsHour(Boolean isHour) {
		this.isHour = isHour;
	}
	public Boolean getIsDay() {
		return isDay;
	}
	public void setIsDay(Boolean isDay) {
		this.isDay = isDay;
	}
	public Boolean getIsMonth() {
		return isMonth;
	}
	public void setIsMonth(Boolean isMonth) {
		this.isMonth = isMonth;
	}
	public Boolean getIsYear() {
		return isYear;
	}
	public void setIsYear(Boolean isYear) {
		this.isYear = isYear;
	}
	public Boolean getIsFormating() {
		return isFormating;
	}
	public void setIsFormating(Boolean isFormating) {
		this.isFormating = isFormating;
	}
	public Boolean getWithInfo() {
		return withInfo;
	}
	public void setWithInfo(Boolean withInfo) {
		this.withInfo = withInfo;
	}
	public String getGroupeMobile() {
		return groupeMobile;
	}
	public void setGroupeMobile(String groupeMobile) {
		this.groupeMobile = groupeMobile;
	}
	public Boolean getIsForGraph() {
		return isForGraph;
	}
	public void setIsForGraph(Boolean isForGraph) {
		this.isForGraph = isForGraph;
	}
	public String getUserLogin() {
		return userLogin;
	}
	public void setUserLogin(String userLogin) {
		this.userLogin = userLogin;
	}
	public String getStart() {
		return start;
	}
	public void setStart(String start) {
		this.start = start;
	}
	public String getEnd() {
		return end;
	}
	public void setEnd(String end) {
		this.end = end;
	}
	
	
	
}