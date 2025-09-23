package com.careconnect.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.careconnect.dto.PatientNotetakerConfigDTO;
import com.careconnect.exception.AppException;
import com.careconnect.service.PatientNotetakerService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestBody;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/v1/api/patient-notetaker")
@Tag(name = "Patient Notetaker", description = "Endpoints for managing data for Medical Notetaker")
@RequiredArgsConstructor
public class PatientNotetakerController {
    
    private final PatientNotetakerService patientNotetakerService;

    @GetMapping("/{patientId}/config")
    @Operation(
        summary = "Get Patient Notetaker Configuration",
        description = "Retrieve the notetaker configuration for a specific patient by patientId.",
        tags = {"Medical Notetaker", "Settings"}
    )
    public ResponseEntity<PatientNotetakerConfigDTO> getPatientNoteTakerConfig(
            @PathVariable Long patientId) {

        PatientNotetakerConfigDTO patientNotetakerConfig;
        try {
            patientNotetakerConfig = patientNotetakerService.getNotetakerConfigByPatientId(patientId);
        }
        catch(AppException ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
        return ResponseEntity.ok(patientNotetakerConfig);
    }

    @PutMapping("/{patientId}/config")
    @Operation(
        summary = "Update Patient Notetaker Configuration",
        description = "Update the notetaker configuration for a specific patient by patientId.",
        tags = {"Medical Notetaker", "Settings"}
    )
    public ResponseEntity<PatientNotetakerConfigDTO> updatePatientNoteTakerConfig(
            @PathVariable Long patientId,
            @RequestBody PatientNotetakerConfigDTO configDTO) {

        PatientNotetakerConfigDTO updatedConfig;
        try {
            updatedConfig = patientNotetakerService.createOrUpdatePatientNotetakerConfig(patientId, configDTO);
        }
        catch (AppException ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
        return ResponseEntity.ok(updatedConfig);
    }
}