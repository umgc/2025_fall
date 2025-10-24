package com.careconnect.repository.evv;

import com.careconnect.model.evv.EvvParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;


public interface EvvParticipantRepository extends JpaRepository<EvvParticipant, Long> {
    Optional<EvvParticipant> findByMaNumber(String maNumber);
}
