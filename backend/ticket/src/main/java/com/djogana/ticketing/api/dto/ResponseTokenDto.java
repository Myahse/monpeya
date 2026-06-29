package com.djogana.ticketing.api.dto;

import lombok.Data;

@Data
public class ResponseTokenDto {
    private String access_token = "access_token";
    private String token_type;
    private String expires_in;
    private String scope;

    
}
