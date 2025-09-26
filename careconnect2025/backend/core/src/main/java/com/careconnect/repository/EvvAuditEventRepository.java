package com.careconnect.repository;

import com.careconnect.model.EvvAuditEvent;
import org.springframework.data.jpa.repository.JpaRepository;


public interface EvvAuditEventRepository extends JpaRepository<EvvAuditEvent, Long> { }
