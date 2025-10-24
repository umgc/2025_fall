package com.careconnect.repository;

import com.careconnect.model.VialOfLife;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface VialOfLifeRepository extends JpaRepository<VialOfLife, Long> {
    Optional<VialOfLife> findByPatientId(Long patientId);
}
