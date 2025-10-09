package com.careconnect.controller;

import com.careconnect.model.EvvRecord;
import com.careconnect.repository.EvvRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/evv/records") @RequiredArgsConstructor
public class EvvQueryController {
    private final EvvRecordRepository evvRecordRepository;

    @GetMapping
    public List<EvvRecord> list(@RequestParam(required = false) String status, @RequestParam(required = false) Long caregiverId) {
        if (status != null && caregiverId != null) return evvRecordRepository.findByCaregiverIdAndStatus(caregiverId, status);
        if (status != null) return evvRecordRepository.findByStatus(status);
        return evvRecordRepository.findAll();
    }
}
