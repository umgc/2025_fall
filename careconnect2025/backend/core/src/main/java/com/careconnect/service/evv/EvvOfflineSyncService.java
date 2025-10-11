package com.careconnect.service.evv;

import com.careconnect.model.evv.EvvOfflineQueue;
import com.careconnect.model.evv.EvvRecord;
import com.careconnect.repository.evv.EvvOfflineQueueRepository;
import com.careconnect.repository.evv.EvvRecordRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

@Service @RequiredArgsConstructor @Slf4j
public class EvvOfflineSyncService {
    
    private final EvvOfflineQueueRepository offlineQueueRepository;
    private final EvvRecordRepository recordRepository;
    private final EvvSubmissionService submissionService;
    private final AuditLogger audit;
    
    private static final int MAX_SYNC_ATTEMPTS = 3;
    private static final int RETRY_DELAY_MINUTES = 30;
    
    @Scheduled(fixedDelay = 60000) // Run every minute
    public void syncOfflineRecords() {
        try {
            List<EvvOfflineQueue> pendingItems = offlineQueueRepository.findPendingSyncItems(MAX_SYNC_ATTEMPTS);
            
            for (EvvOfflineQueue queueItem : pendingItems) {
                try {
                    syncQueueItem(queueItem);
                } catch (Exception e) {
                    log.error("Failed to sync queue item {}: {}", queueItem.getId(), e.getMessage());
                    queueItem.markFailed(e.getMessage());
                    offlineQueueRepository.save(queueItem);
                }
            }
        } catch (Exception e) {
            log.error("Error in offline sync process: {}", e.getMessage());
        }
    }
    
    @Transactional
    public void syncQueueItem(EvvOfflineQueue queueItem) {
        queueItem.markSyncing();
        offlineQueueRepository.save(queueItem);
        
        try {
            EvvRecord record = recordRepository.findById(queueItem.getRecordId())
                    .orElseThrow(() -> new RuntimeException("Record not found"));
            
            // Update record status based on operation type
            switch (queueItem.getOperationType()) {
                case "CREATE":
                    record.markSynced();
                    record.setStatus("PENDING_REVIEW");
                    recordRepository.save(record);
                    
                    // Queue for submission if confirmed
                    if ("CONFIRMED".equals(record.getStatus())) {
                        submissionService.queueForSubmission(record, queueItem.getCaregiverId());
                    }
                    break;
                    
                case "UPDATE":
                    record.markSynced();
                    recordRepository.save(record);
                    break;
                    
                case "DELETE":
                    // Handle deletion if needed
                    break;
            }
            
            queueItem.markSynced();
            offlineQueueRepository.save(queueItem);
            
            audit.log(record, queueItem.getCaregiverId(), "OFFLINE_SYNCED", 
                java.util.Map.of("queueItemId", queueItem.getId()));
            
        } catch (Exception e) {
            queueItem.markFailed(e.getMessage());
            offlineQueueRepository.save(queueItem);
            throw e;
        }
    }
    
    @Transactional
    public void retryFailedSyncs() {
        OffsetDateTime retryAfter = OffsetDateTime.now().minusMinutes(RETRY_DELAY_MINUTES);
        List<EvvOfflineQueue> failedItems = offlineQueueRepository.findFailedItemsForRetry(retryAfter);
        
        for (EvvOfflineQueue queueItem : failedItems) {
            if (queueItem.getSyncAttempts() < MAX_SYNC_ATTEMPTS) {
                queueItem.setSyncStatus("PENDING");
                offlineQueueRepository.save(queueItem);
            }
        }
    }
    
    @Transactional
    public void syncCaregiverOfflineData(Long caregiverId) {
        List<EvvOfflineQueue> caregiverItems = offlineQueueRepository.findPendingItemsByCaregiver(caregiverId);
        
        for (EvvOfflineQueue queueItem : caregiverItems) {
            try {
                syncQueueItem(queueItem);
            } catch (Exception e) {
                log.error("Failed to sync caregiver {} queue item {}: {}", caregiverId, queueItem.getId(), e.getMessage());
            }
        }
    }
    
    public List<EvvOfflineQueue> getOfflineQueueStatus(Long caregiverId) {
        return offlineQueueRepository.findByCaregiverIdAndSyncStatus(caregiverId, "PENDING");
    }
}

