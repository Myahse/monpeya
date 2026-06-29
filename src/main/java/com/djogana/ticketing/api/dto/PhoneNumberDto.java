package com.djogana.ticketing.api.dto;

import lombok.Data;

@Data
public class PhoneNumberDto {
    private String countryCode;
    private String number;
}
