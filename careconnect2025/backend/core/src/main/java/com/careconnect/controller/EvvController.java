package com.careconnect.controller;

import com.careconnect.dto.evv.*;
import com.careconnect.model.evv.EvvRecord;
import com.careconnect.model.evv.EvvCorrection;
import com.careconnect.model.evv.EvvOfflineQueue;
import com.careconnect.service.evv.EvvService;
import com.careconnect.service.evv.EvvSubmissionService;
import com.careconnect.service.evv.EvvOfflineSyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController @RequestMapping("/v1/api/evv") @RequiredArgsConstructor
public class EvvController {
    private final EvvService evvService;
    private final EvvSubmissionService submitter;
    private final EvvOfflineSyncService offlineSyncService;

    private static final Long DEFAULT_USER_ID = 1L;

    @PostMapping("/records")
    public ResponseEntity<EvvRecord> create(@RequestBody EvvRecordRequestDto req) {
        return ResponseEntity.ok(evvService.createRecord(req, DEFAULT_USER_ID));
    }

    @PostMapping("/records/{id}/review")
    public ResponseEntity<EvvRecord> review(@PathVariable Long id, @RequestBody EvvReviewRequest action) {
        var rec = evvService.review(id, action.isApprove(), DEFAULT_USER_ID, action.getComment());
        if (action.isApprove()) submitter.queueForSubmission(rec, DEFAULT_USER_ID);
        return ResponseEntity.ok(rec);
    }

    @PostMapping("/records/offline")
    public ResponseEntity<EvvRecord> createOfflineRecord(@RequestBody EvvRecordRequestDto req,
                                                         @RequestHeader("X-Device-ID") String deviceId) {
        return ResponseEntity.ok(evvService.createOfflineRecord(req, DEFAULT_USER_ID, deviceId));
    }

    @PostMapping("/records/correct")
    public ResponseEntity<EvvRecord> correctRecord(@RequestBody EvvCorrectionRequestDto req) {
        return ResponseEntity.ok(evvService.correctRecord(req, DEFAULT_USER_ID));
    }

    @PostMapping("/records/eor-approve")
    public ResponseEntity<EvvRecord> approveEor(@RequestBody EorApprovalRequestDto req) {
        return ResponseEntity.ok(evvService.approveEor(req, DEFAULT_USER_ID));
    }

    @GetMapping("/records/search")
    public ResponseEntity<Page<EvvRecord>> searchRecords(EvvSearchRequestDto searchRequest) {
        return ResponseEntity.ok(evvService.searchRecords(searchRequest));
    }

    @GetMapping("/records/pending-eor-approvals")
    public ResponseEntity<List<EvvRecord>> getPendingEorApprovals() {
        return ResponseEntity.ok(evvService.getPendingEorApprovals());
    }

    @GetMapping("/corrections/pending")
    public ResponseEntity<List<EvvCorrection>> getPendingCorrections() {
        return ResponseEntity.ok(evvService.getPendingCorrections());
    }

    @PostMapping("/corrections/{id}/approve")
    public ResponseEntity<EvvCorrection> approveCorrection(@PathVariable Long id,
                                                           @RequestParam(required = false) String comment) {
        return ResponseEntity.ok(evvService.approveCorrection(id, DEFAULT_USER_ID, comment));
    }

    @GetMapping("/offline/queue")
    public ResponseEntity<List<EvvOfflineQueue>> getOfflineQueue() {
        return ResponseEntity.ok(evvService.getOfflineQueue(DEFAULT_USER_ID));
    }

    @PostMapping("/offline/sync")
    public ResponseEntity<String> syncOfflineData() {
        offlineSyncService.syncCaregiverOfflineData(DEFAULT_USER_ID);
        return ResponseEntity.ok("Offline data sync initiated");
    }

    @GetMapping("/offline/status")
    public ResponseEntity<List<EvvOfflineQueue>> getOfflineStatus() {
        return ResponseEntity.ok(offlineSyncService.getOfflineQueueStatus(DEFAULT_USER_ID));
    }
}