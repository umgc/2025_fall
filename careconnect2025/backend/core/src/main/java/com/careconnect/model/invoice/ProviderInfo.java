package com.careconnect.model.invoice;


<<<<<<< HEAD
public record ProviderInfo(String name, String address, String phone, String email) {}

=======
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
>>>>>>> origin/team_d_ocr_textract
