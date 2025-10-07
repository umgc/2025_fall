package com.careconnect.model.invoice;

<<<<<<< HEAD
public record InvoiceDates(String serviceDate, String billedDate, String dueDate, String paidDate) {}
=======
import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;

@Data
@Builder
public class InvoiceDates {
    private LocalDate statementDate;
    private LocalDate dueDate;
    private LocalDate paidDate;
}
>>>>>>> origin/team_d_ocr_textract
