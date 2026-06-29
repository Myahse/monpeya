package com.djogana.ticketing.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "Event action by public event code")
public class EventActionDto implements CodeClientHolder {

	@Schema(description = "Public event code", example = "EVT-2026-A1B2C3D4", requiredMode = Schema.RequiredMode.REQUIRED)
	private String eventCode;

	@Schema(description = "Creator Peya codeClient (required for publish)", example = "YOUR_PEYA_CODE")
	private String codeClient;
}
