package com.careconnect.dto.invoice;


public class InvoiceResponseDto {
    public InvoiceDto invoice;
    public boolean duplicate;
    public String message;                // human-readable note
    public String duplicateId;            // existing invoice id if duplicate
    public String duplicateInvoiceNumber; // existing invoice number if available
}