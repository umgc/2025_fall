package com.careconnect.model.invoice;

<<<<<<< HEAD
public record Amounts(Double totalCharges, Double totalAdjustments, Double total, Double amountDue) {}
=======
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
>>>>>>> origin/team_d_ocr_textract
