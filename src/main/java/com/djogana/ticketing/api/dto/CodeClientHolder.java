package com.djogana.ticketing.api.dto;

/**
 * Marker for request payloads that identify a Peya user via {@code W_Clients.CODE_CLIENT}.
 * Ticketing does not maintain a local user table — every actor is resolved from {@code W_Clients}.
 */
public interface CodeClientHolder {

	String getCodeClient();
}
