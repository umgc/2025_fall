package com.careconnect.service;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.careconnect.model.PatientNote;
import com.careconnect.model.UserFile;
import com.careconnect.repository.PatientNoteRepository;


@Service
public class PatientNotetakerService {
    
    @Autowired
    private PatientNoteRepository patientNoteRepository;

    @Autowired
    public PatientNotetakerService(PatientNoteRepository patientNoteRepository) {
        this.patientNoteRepository = patientNoteRepository;
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

    // private void validatePatientId(Long patientId) {
    //     if(patientService.getPatientById(patientId) == null) {
    //         log.error("Patient with ID {} not found.", patientId);
    //         throw new IllegalArgumentException("Patient not found");
    //     }
    // }
}
