package com.careconnect.controller;

import com.careconnect.dto.MedicationDTO;
import com.careconnect.service.MedicationService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/v1/api/patients")
/// The following lines were copied from PatientController
@Tag(name = "Medication Management", description = "Endpoint for medication list access")
///@SecurityRequirement(name = "Bearer Authentication")
/// TODO: Determine if these class should implement authentication or piggyback on patient services somehow
/// Does seem a waste to copy all off patient
public class MedicationController {

    @Autowired
    private MedicationService medicationService;

    /// TODO: Verify the correct URL for this endpoint

}
