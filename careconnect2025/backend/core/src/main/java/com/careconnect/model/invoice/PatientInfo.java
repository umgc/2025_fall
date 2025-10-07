package com.careconnect.model.invoice;

<<<<<<< HEAD
public record PatientInfo(String name, String address, String accountNumber, String billingAddress) {}

=======
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
>>>>>>> origin/team_d_ocr_textract
