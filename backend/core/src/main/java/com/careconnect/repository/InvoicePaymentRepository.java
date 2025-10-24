package com.careconnect.repository;


import com.careconnect.model.invoice.InvoicePayment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InvoicePaymentRepository extends JpaRepository<InvoicePayment, String> {
}
