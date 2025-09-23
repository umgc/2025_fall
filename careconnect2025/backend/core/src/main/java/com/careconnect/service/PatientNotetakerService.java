package com.careconnect.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.careconnect.dto.PatientNotetakerConfigDTO;
import com.careconnect.model.PatientNote;
import com.careconnect.model.PatientNotetakerConfig;
import com.careconnect.model.UserFile;
import com.careconnect.repository.PatientNoteRepository;
import com.careconnect.repository.PatientNotetakerConfigRepository;


@Service
public class PatientNotetakerService {
    
    private final PatientNoteRepository patientNoteRepository;
    private final PatientNotetakerConfigRepository patientNotetakerConfigRepository;
    private final PatientService patientService;

    public PatientNotetakerService(PatientNoteRepository patientNoteRepository, 
        PatientNotetakerConfigRepository patientNotetakerConfigRepository, 
        PatientService patientService
        ) {
        this.patientNoteRepository = patientNoteRepository;
        this.patientNotetakerConfigRepository = patientNotetakerConfigRepository;
        this.patientService = patientService;
    }

    public List<UserFile> getNotetakerNotesForPatient(Long patientId) {
        return new ArrayList<UserFile>();
    }

    public PatientNote saveNotetakerNote(Long patientId,  String fileData) {
        return new PatientNote();   
    }

    public List<String> detectKeyWords(String fileData) {
        List<String> foundKeywords = new ArrayList<String>();
        return foundKeywords;
    }

    public PatientNotetakerConfigDTO getNotetakerConfigByPatientId(Long patientId) {
        // validatePatientId(patientId);
        return new PatientNotetakerConfigDTO(patientNotetakerConfigRepository.findByPatientId(patientId));
    }

    @Transactional
    public PatientNotetakerConfigDTO createOrUpdatePatientNotetakerConfig(Long patientId, PatientNotetakerConfigDTO configDTO) {
        // validatePatientId(patientId);
        if(configDTO == null) {
            throw new IllegalArgumentException("Configuration data is required.");
        }

        PatientNotetakerConfig existingConfig = patientNotetakerConfigRepository.findByPatientId(patientId);
        if(existingConfig == null) {
            PatientNotetakerConfig newConfig = configDTO.toEntity();
            newConfig.setPatientId(patientId);
            newConfig.setUpdatedAt(LocalDateTime.now());
            return new PatientNotetakerConfigDTO(patientNotetakerConfigRepository.save(newConfig));
        }

        existingConfig.setIsEnabled(configDTO.getIsEnabled()); 
        existingConfig.setPatientId(patientId);
        existingConfig.setPermitCaregiverAccess(configDTO.getPermitCaregiverAccess());
        existingConfig.setTriggerKeywords(configDTO.getTriggerKeywords());
        existingConfig.setUpdatedAt(LocalDateTime.now());
        return new PatientNotetakerConfigDTO(patientNotetakerConfigRepository.save(existingConfig));
    }

    private void validatePatientId(Long patientId) {
        if(patientService.getPatientById(patientId) == null) {
            throw new IllegalArgumentException("Patient not found");
        }
    }
}
