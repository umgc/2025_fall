package com.careconnect.controller;

import com.careconnect.model.checkins.CheckIn;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/checkins")
@Tag(name = "Check-In", description = "Endpoint for the virtual Check-In, including both patient submitting and caregiver checking")
public class CheckInController {

    @PostMapping()
    public ResponseEntity<CheckIn> patientCheckIn()
    {
        //This function creates patient check-ins. Presumably by accessing the current data from the screen.
        //TODO:Check how that works
        return  new ResponseEntity<CheckIn>();
    }

    @GetMapping()
    public List<ResponseEntity<CheckIn>> getCheckIns()
    {
        //This function lists patient check-ins that meet a criteria
        return new List<ResponseEntity<CheckIn>>[];
    }

    @GetMapping("/{id}")
    public CheckIn getCheckIn(@PathVariable Long id)
    {
        //This function retrieves a specific check-in by ID
        CheckIn target = CheckInService.getCheckInByID(id);
        //Validate access to checkIn, perform checks
        return target;
    }

    @PutMapping("/{id}")
    public  ResponseEntity<CheckIn> updateCheckIn()
    {
        //This function updates a specific check-in by ID
        return new ResponseEntity<CheckIn>();
    }
}
