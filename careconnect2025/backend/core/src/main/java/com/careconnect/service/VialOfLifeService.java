package com.ccareconnect.service; 

import com.careconnect.model.VialOfLife;
import com.careconnect.repository.VialOfLifeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class VialContactsServicePatch {

    @Autowired
    private VialOfLifeRepository repo;

    // Update only the emergencyContacts list for a given patient
    public Optional<VialOfLife> updateContacts(Long patientId, List<String> flattenedContacts) {
        Optional<VialOfLife> opt = repo.findByPatientId(patientId);
        if (opt.isEmpty()) return Optional.empty();
        VialOfLife v = opt.get();
        v.setEmergencyContacts(flattenedContacts);
        return Optional.of(repo.save(v));
    }
}

