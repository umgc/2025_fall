package com.careconnect.repository;

import com.careconnect.model.invoice.Invoice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.math.BigDecimal;
import java.util.Optional;

public interface InvoiceRepository extends JpaRepository<Invoice, String>, JpaSpecificationExecutor<Invoice> {

    // Exact match on provider + total + invoiceNumber, newest first
    Optional<Invoice> findTopByProviderNameIgnoreCaseAndTotalAndInvoiceNumberOrderByCreatedAtDesc(
            String providerName, BigDecimal total, String invoiceNumber
    );

    // Fallback: provider + total in a window, newest first
    Optional<Invoice> findTopByProviderNameIgnoreCaseAndTotalBetweenOrderByCreatedAtDesc(
            String providerName, BigDecimal minTotal, BigDecimal maxTotal
    );
}
