package com.careconnect.repository;

import com.careconnect.model.EvvRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface EvvRecordRepository extends JpaRepository<EvvRecord,Long> {
    List<EvvRecord> findByCaregiverIdAndStatus(Long caregiverId, String status);
}
