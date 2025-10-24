package com.careconnect.model.invoice;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PatientInfo {
    private String name;
    private String address;
    private String accountNumber;
    private String billingAddress;
}