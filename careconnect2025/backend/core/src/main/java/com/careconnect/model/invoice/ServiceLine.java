package com.careconnect.model.invoice;

<<<<<<< HEAD
public record ServiceLine(String description, String serviceCode, String serviceDate,
                          Double charge, Double patientBalance, Double insuranceAdjustments) {}
=======
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "invoice_service_lines")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ServiceLine {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id")
    private Invoice invoice;

    private String description;
    private String serviceCode;
    private OffsetDateTime serviceDate;
    private BigDecimal charge;
    private BigDecimal patientBalance;
    private BigDecimal insuranceAdjustments;
}
>>>>>>> origin/team_d_ocr_textract
