package com.careconnect.model.invoice;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class Amounts {
    private Double totalCharges;
    private Double totalAdjustments;
    private Double total;
    private Double amountDue;
}