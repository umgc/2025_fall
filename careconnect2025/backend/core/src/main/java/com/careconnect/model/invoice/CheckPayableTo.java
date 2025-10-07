package com.careconnect.model.invoice;
<<<<<<< HEAD

public record CheckPayableTo(String name, String address, String reference) {}
=======
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CheckPayableTo {
    private String name;
    private String address;
    private String reference;
}
>>>>>>> origin/team_d_ocr_textract
