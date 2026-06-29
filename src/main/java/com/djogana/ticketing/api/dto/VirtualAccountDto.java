package com.djogana.ticketing.api.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class VirtualAccountDto {
    private String expirationDate;
    private String firstName;
    private String middleName;
    private String lastName;
    private String preferredName;
    private String otherAccountId;
    private String otherCompanyName;
    private String address1;
    private String address2;
    private String address3;
    private String city;
    private String country;
    private String stateRegion;
    private String postalCode;
    private String birthDate;
    private Integer idType;
    private String idValue;
    private PhoneNumberDto mobilePhoneNumber;
    private PhoneNumberDto alternatePhoneNumber;
    private String emailAddress;
    private String accountSource;
    private Integer subCompany;
    private Integer referredBy;
    @JsonProperty("return")
    private String returnType;  
    private String solId;
    private String bvn;
}
