package com.careconnect.model.invoice;

<<<<<<< HEAD
import java.util.List;

public record PaymentReferences(String paymentLink, String qrCodeUrl, String notes, List<String> supportedMethods) {}

=======

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import java.util.List;

@Builder
@Data
@AllArgsConstructor
public class PaymentReferences {
    private String paymentLink;
    private String qrCodeUrl;
    private String notes;
    private List<String> supportedMethods;
}
>>>>>>> origin/team_d_ocr_textract
