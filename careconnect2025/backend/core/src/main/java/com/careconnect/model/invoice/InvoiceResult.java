package com.careconnect.model.invoice;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Data
@Builder
public class InvoiceResult {
    private String vendorName;
    private String invoiceId;
    private String invoiceDate; // ISO 8601 string
    private String dueDate;     // optional
    private String currency;    // e.g. USD
    private BigDecimal subtotal;
    private BigDecimal tax;
    private BigDecimal total;
    private String purchaseOrder;
    private Map<String, String> otherFields; // any extra normalized fields
    private List<InvoiceItem> items;

    @Data
    @Builder
    public static class InvoiceItem {
        private String description;
        private String productCode;
        private String unit;
        private BigDecimal quantity;
        private BigDecimal unitPrice;
        private BigDecimal amount;
    }
}
