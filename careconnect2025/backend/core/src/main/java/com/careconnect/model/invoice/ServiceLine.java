package com.careconnect.model.invoice;

public record ServiceLine(String description, String serviceCode, String serviceDate,
                          Double charge, Double patientBalance, Double insuranceAdjustments) {}
