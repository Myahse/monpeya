package com.djogana.ticketing.api.dto;

import lombok.Data;

@Data
public class FundTransferResponseDto {

    private Long transactionId;

    private Double newBalance;
}
