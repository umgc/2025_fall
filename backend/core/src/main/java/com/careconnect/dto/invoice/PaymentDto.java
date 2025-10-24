package com.careconnect.dto.invoice;

import java.math.BigDecimal;

public class PaymentDto {
    public String id;
    public String confirmationNumber;
    public String date; // ISO-8601 string (OffsetDateTime)
    public String methodKey; // check | credit_card | online | telephone
    public BigDecimal amountPaid;
    public Boolean planEnabled;
    public Integer planDurationMonths;
    public String createdBy;
}
