package com.djogana.ticketing.api.dto;

import com.fasterxml.jackson.annotation.JsonAlias;

import lombok.Data;

@Data
public class AccountStatusUpdateDto {

    @JsonAlias({"last4", "registrationLast4Digits", "cardLast4Digits"})
    private String last4Digits;

    @JsonAlias({"gsmPrincipale", "phoneNumber", "mobile", "numerotele", "mobile_phone_number"})
    private String mobilePhoneNumber;

    @JsonAlias({"status", "cardStatus", "newStatus", "new_card_status"})
    private String newCardStatus;
}
