package com.careconnect.controller;

import com.careconnect.model.CheckIn;
import com.careconnect.service.CheckInService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/checkins")
@Tag(name = "Check-In", description = "Endpoint for the virtual Check-In, including both patient submitting and caregiver checking")
public class CheckInController {

    @Autowired
    private CheckInService checkInService;

    @PostMapping()
    public ResponseEntity<CheckIn> patientCheckIn() {
        // TODO: Replace with actual patient check-in logic later
        return ResponseEntity.ok(new CheckIn());
    }

    @GetMapping()
    public ResponseEntity<List<CheckIn>> getCheckIns() {
        // Fetch all check-ins (placeholder)
        return ResponseEntity.ok(checkInService.getAllCheckIns());
    }

    @GetMapping("/{id}")
    public ResponseEntity<CheckIn> getCheckIn(@PathVariable Long id) {
        // Retrieve a specific check-in by ID
        CheckIn target = checkInService.getCheckInByID(id);
        return ResponseEntity.ok(target);
    }

    @PutMapping("/{id}")
    public ResponseEntity<CheckIn> updateCheckIn(@PathVariable Long id) {
        // TODO: Implement update logic later
        return ResponseEntity.ok(new CheckIn());
    }
}