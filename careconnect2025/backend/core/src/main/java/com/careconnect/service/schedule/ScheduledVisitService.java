package com.careconnect.service.schedule;

import com.careconnect.dto.schedule.ScheduledVisitRequest;
import com.careconnect.dto.schedule.ScheduledVisitResponse;
import com.careconnect.dto.schedule.ScheduledVisitSummary;
import com.careconnect.model.schedule.ScheduledVisit;
import com.careconnect.repository.PatientRepository;
import com.careconnect.repository.schedule.ScheduledVisitRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ScheduledVisitService {
    
    private final ScheduledVisitRepository scheduledVisitRepository;
    private final PatientRepository patientRepository;
    
    @Transactional
    public ScheduledVisitResponse createScheduledVisit(Long caregiverId, ScheduledVisitRequest request) {
        ScheduledVisit visit = new ScheduledVisit();
        visit.setCaregiverId(caregiverId);
        visit.setPatientId(request.getPatientId());
        visit.setServiceType(request.getServiceType());
        visit.setScheduledDate(request.getScheduledDate());
        visit.setScheduledTime(request.getScheduledTime());
        visit.setDurationMinutes(request.getDurationMinutes());
        visit.setPriority(request.getPriority());
        visit.setNotes(request.getNotes());
        visit.setStatus("Scheduled");
        
        ScheduledVisit savedVisit = scheduledVisitRepository.save(visit);
        
        String patientName = getPatientName(savedVisit.getPatientId());
        return new ScheduledVisitResponse(savedVisit, patientName);
    }
    
    @Transactional(readOnly = true)
    public List<ScheduledVisitResponse> getScheduledVisits(Long caregiverId) {
        List<ScheduledVisit> visits = scheduledVisitRepository.findByCaregiverId(caregiverId);
        return visits.stream()
            .map(visit -> new ScheduledVisitResponse(visit, getPatientName(visit.getPatientId())))
            .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public List<ScheduledVisitResponse> getScheduledVisitsByDate(Long caregiverId, LocalDate date) {
        List<ScheduledVisit> visits = scheduledVisitRepository.findByCaregiverIdAndScheduledDate(caregiverId, date);
        return visits.stream()
            .map(visit -> new ScheduledVisitResponse(visit, getPatientName(visit.getPatientId())))
            .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public List<ScheduledVisitResponse> getScheduledVisitsBetweenDates(
        Long caregiverId, 
        LocalDate startDate, 
        LocalDate endDate
    ) {
        List<ScheduledVisit> visits = scheduledVisitRepository
            .findByCaregiverIdAndScheduledDateBetween(caregiverId, startDate, endDate);
        return visits.stream()
            .map(visit -> new ScheduledVisitResponse(visit, getPatientName(visit.getPatientId())))
            .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public ScheduledVisitSummary getVisitSummary(Long caregiverId) {
        LocalDate today = LocalDate.now();
        LocalTime currentTime = LocalTime.now();
        LocalTime readyThreshold = currentTime.plusMinutes(30);
        
        long overdue = scheduledVisitRepository.countOverdueVisits(caregiverId, today, currentTime);
        long ready = scheduledVisitRepository.countReadyVisits(caregiverId, today, readyThreshold);
        long upcoming = scheduledVisitRepository.countUpcomingVisits(caregiverId, today, readyThreshold);
        long totalToday = scheduledVisitRepository.countTodayVisits(caregiverId, today);
        
        return new ScheduledVisitSummary(overdue, ready, upcoming, totalToday);
    }
    
    @Transactional(readOnly = true)
    public List<ScheduledVisitResponse> getOverdueVisits(Long caregiverId) {
        LocalDate today = LocalDate.now();
        LocalTime currentTime = LocalTime.now();
        
        List<ScheduledVisit> visits = scheduledVisitRepository
            .findOverdueVisits(caregiverId, today, currentTime);
        
        return visits.stream()
            .map(visit -> new ScheduledVisitResponse(visit, getPatientName(visit.getPatientId())))
            .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public List<ScheduledVisitResponse> getReadyVisits(Long caregiverId) {
        LocalDate today = LocalDate.now();
        LocalTime currentTime = LocalTime.now();
        LocalTime readyThreshold = currentTime.plusMinutes(30);
        
        List<ScheduledVisit> visits = scheduledVisitRepository
            .findReadyVisits(caregiverId, today, readyThreshold);
        
        return visits.stream()
            .map(visit -> new ScheduledVisitResponse(visit, getPatientName(visit.getPatientId())))
            .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public List<ScheduledVisitResponse> getUpcomingVisits(Long caregiverId) {
        LocalDate today = LocalDate.now();
        LocalTime currentTime = LocalTime.now();
        LocalTime readyThreshold = currentTime.plusMinutes(30);
        
        List<ScheduledVisit> visits = scheduledVisitRepository
            .findUpcomingVisits(caregiverId, today, readyThreshold);
        
        return visits.stream()
            .map(visit -> new ScheduledVisitResponse(visit, getPatientName(visit.getPatientId())))
            .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public ScheduledVisitResponse getScheduledVisit(Long visitId) {
        ScheduledVisit visit = scheduledVisitRepository.findById(visitId)
            .orElseThrow(() -> new RuntimeException("Scheduled visit not found with id: " + visitId));
        
        String patientName = getPatientName(visit.getPatientId());
        return new ScheduledVisitResponse(visit, patientName);
    }
    
    @Transactional
    public ScheduledVisitResponse updateScheduledVisit(Long visitId, ScheduledVisitRequest request) {
        ScheduledVisit visit = scheduledVisitRepository.findById(visitId)
            .orElseThrow(() -> new RuntimeException("Scheduled visit not found with id: " + visitId));
        
        visit.setPatientId(request.getPatientId());
        visit.setServiceType(request.getServiceType());
        visit.setScheduledDate(request.getScheduledDate());
        visit.setScheduledTime(request.getScheduledTime());
        visit.setDurationMinutes(request.getDurationMinutes());
        visit.setPriority(request.getPriority());
        visit.setNotes(request.getNotes());
        
        ScheduledVisit updatedVisit = scheduledVisitRepository.save(visit);
        
        String patientName = getPatientName(updatedVisit.getPatientId());
        return new ScheduledVisitResponse(updatedVisit, patientName);
    }
    
    @Transactional
    public void cancelScheduledVisit(Long visitId) {
        ScheduledVisit visit = scheduledVisitRepository.findById(visitId)
            .orElseThrow(() -> new RuntimeException("Scheduled visit not found with id: " + visitId));
        
        visit.markCancelled();
        scheduledVisitRepository.save(visit);
    }
    
    @Transactional
    public ScheduledVisitResponse updateVisitStatus(Long visitId, String status) {
        ScheduledVisit visit = scheduledVisitRepository.findById(visitId)
            .orElseThrow(() -> new RuntimeException("Scheduled visit not found with id: " + visitId));
        
        visit.setStatus(status);
        ScheduledVisit updatedVisit = scheduledVisitRepository.save(visit);
        
        String patientName = getPatientName(updatedVisit.getPatientId());
        return new ScheduledVisitResponse(updatedVisit, patientName);
    }
    
    @Transactional
    public void deleteScheduledVisit(Long visitId) {
        scheduledVisitRepository.deleteById(visitId);
    }
    
    private String getPatientName(Long patientId) {
        return patientRepository.findById(patientId)
            .map(patient -> patient.getFirstName() + " " + patient.getLastName())
            .orElse("Unknown Patient");
    }
}
