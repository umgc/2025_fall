package com.careconnect.controller;

import com.careconnect.model.checkins.CheckIn;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/checkins")
@Tag(name = "Check-In", description = "Endpoint for the virtual Check-In, including both patient submitting and ")
public class CheckInController {

    @PostMapping()
    public ResponseEntity<CheckIn> patientCheckIn()
    {
        return  new ResponseEntity<CheckIn>();
    }

    @GetMapping()
    public List<ResponseEntity<CheckIn>> getCheckIns()
    {
        return new List<ResponseEntity<CheckIn>>[];
    }

    @GetMapping("/{id}")
    public CheckIn getCheckIn()
    {
        return new CheckIn();
    }

    @PutMapping("/{id}")
    public  ResponseEntity<CheckIn> updateCheckIn()
    {
        return new ResponseEntity<CheckIn>();
    }
}
