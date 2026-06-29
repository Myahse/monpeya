package com.djogana.ticketing.api.dto;

import lombok.Data;


@Data
public class PersonalizedAccountDto {

    private String codeClient;

    private String firstName;
    private String lastName;
    private String preferredName;
    private String address1;
    private String city;
    private String country;
    private String stateRegion;
    private String birthDate;

    private String login;

   
    private Integer idType;


    private String idValue;
    private PhoneNumberDto mobilePhoneNumber;
    private String emailAddress;
    private String accountSource;
    private String referredBy;
    private String subCompany;
}
