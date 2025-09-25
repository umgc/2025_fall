package com.careconnect.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.careconnect.dto.PatientNoteDTO;
import com.careconnect.dto.PatientNotetakerConfigDTO;
import com.careconnect.model.PatientNote;
import com.careconnect.model.PatientNotetakerConfig;
import com.careconnect.model.PatientNotetakerKeyword;
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

    public PatientNotetakerConfigDTO getNotetakerConfigByPatientId(Long patientId) {
        validatePatientId(patientId);
        return new PatientNotetakerConfigDTO(patientNotetakerConfigRepository.findByPatientId(patientId));
    }

    @Transactional
    public PatientNotetakerConfigDTO createOrUpdatePatientNotetakerConfig(Long patientId, PatientNotetakerConfigDTO configDTO) {
        validatePatientId(patientId);
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

    public List<PatientNote> getAllNotesForPatient(Long patientId) {
        validatePatientId(patientId);
        return patientNoteRepository.findByPatientId(patientId).orElse(new ArrayList<PatientNote>());
    }

    public PatientNote getNoteById(Long patientId, Long noteId) {
        validatePatientId(patientId);
        return patientNoteRepository.findById(noteId)
            .orElseThrow(() -> new IllegalArgumentException("Note not found"));
    }

    @Transactional
    public PatientNote createNoteForPatient(Long patientId, PatientNoteDTO noteDTO) {
        validatePatientId(patientId);
        if(noteDTO == null) {
            throw new IllegalArgumentException("Note data is required.");
        }
        PatientNote newNote = noteDTO.toEntity();
        newNote.setPatientId(patientId);
        newNote.setCreatedAt(LocalDateTime.now());
        newNote.setUpdatedAt(LocalDateTime.now());
        return patientNoteRepository.save(newNote);
    }

    @Transactional
    public PatientNote updateNoteForPatient(Long patientId, Long noteId, PatientNoteDTO noteDTO) {
        validatePatientId(patientId);
        if(noteDTO == null) {
            throw new IllegalArgumentException("Note data is required.");
        }
        PatientNote existingNote = patientNoteRepository.findById(noteId).orElseThrow();
        existingNote.setPatientId(patientId);
        existingNote.setNote(noteDTO.getNote());
        existingNote.setUpdatedAt(LocalDateTime.now());
        return patientNoteRepository.save(existingNote);
    }

    @Transactional
    public void deleteNoteById(Long noteId) {
        patientNoteRepository.deleteById(noteId);
    }

    private void validatePatientId(Long patientId) {
        if(patientService.getPatientById(patientId) == null) {
            throw new IllegalArgumentException("Patient not found");
        }
    }
    
    private List<String> detectKeyWords(Long patientId, String fileData) {
        List<PatientNotetakerKeyword> keywords = patientNotetakerConfigRepository.findByPatientId(patientId).getTriggerKeywords();
        List<String> foundKeywords = new ArrayList<>();
        //TODO add defaults and parse those out as well.
        for(PatientNotetakerKeyword keyword : keywords) {
            if(fileData.contains(keyword.getKeyword())) {
                foundKeywords.add(keyword.getKeyword());
                triggerEventForKeywords(keyword);
            }
        }
        return foundKeywords;
    }

    private void triggerEventForKeywords(PatientNotetakerKeyword keywords) {
        //TODO implement event trigger
    }

}
