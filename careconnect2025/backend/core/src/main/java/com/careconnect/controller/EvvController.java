package com.careconnect.controller;

import com.careconnect.dto.CreateParticipationRequestDto;
import com.careconnect.dto.EvvRecordRequestDto;
import com.careconnect.dto.EvvReviewRequest;
import com.careconnect.model.User;
import com.careconnect.model.EvvRecord;
import com.careconnect.security.Role;
import com.careconnect.service.EvvService;
import com.careconnect.service.EvvSubmissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/evv") @RequiredArgsConstructor
public class EvvController {
    private final EvvService evvService;
    private final EvvSubmissionService submitter;

    private Long actor(Authentication auth) {
        return ((User)auth.getPrincipal()).getId();
    }

    private String actorEmail(Authentication auth) {
        return ((User)auth.getPrincipal()).getEmail();
    }

    @PostMapping("/participants")
    @PreAuthorize("hasAnyRole('CAREGIVER','ADMIN')")
    public ResponseEntity<?> createParticipant(@RequestBody CreateParticipationRequestDto req, Authentication auth){
        return ResponseEntity.ok(evvService.createParticipant(req, actorEmail(auth))); // REQ 1
    }

    @PostMapping("/records")
    @PreAuthorize("hasAnyRole('CAREGIVER','ADMIN')")
    public ResponseEntity<EvvRecord> create(@RequestBody EvvRecordRequestDto req, Authentication auth){
        return ResponseEntity.ok(evvService.createRecord(req, actor(auth))); // REQ 2 + REQ 4
    }

    @PostMapping("/records/{id}/review")
    @PreAuthorize("hasAnyRole('CAREGIVER','ADMIN')")
    public ResponseEntity<EvvRecord> review(@PathVariable Long id, @RequestBody EvvReviewRequest action, Authentication auth){
        var rec = evvService.review(id, action.isApprove(), actor(auth), action.getComment()); // REQ 3 + REQ 4
        if (action.isApprove()) submitter.queueForSubmission(rec, actor(auth));
        return ResponseEntity.ok(rec);
    }
}

