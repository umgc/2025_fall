package com.careconnect.model.invoice;

import java.util.List;

public record PaymentReferences(String paymentLink, String qrCodeUrl, String notes, List<String> supportedMethods) {}

