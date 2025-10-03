// com.careconnect.repository.CheckInRepository
package com.careconnect.repository;
import com.careconnect.model.CheckIn;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface CheckInRepository extends JpaRepository<CheckIn, Long> {
  List<CheckIn> findByPatient_IdOrderByCreatedAtDesc(Long patientId);
}
