package com.djogana.ticketing.api.dto;

import lombok.Data;

@Data
public class ConsumeTicketDto implements CodeClientHolder {

	private String qrPayload;
	private String consumedPlace;
	private String scannerCodeClient;
	private String scannerDeviceId;

	@Override
	public String getCodeClient() {
		return scannerCodeClient;
	}
}
