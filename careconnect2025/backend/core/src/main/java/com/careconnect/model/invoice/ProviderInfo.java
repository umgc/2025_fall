package com.careconnect.model.invoice;


import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Builder
@Data
@AllArgsConstructor
public class ProviderInfo {
    private String name;
    private String address;
    private String phone;
    private String email;
}
