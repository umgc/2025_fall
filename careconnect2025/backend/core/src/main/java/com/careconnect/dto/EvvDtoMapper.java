package com.careconnect.dto;

import com.careconnect.dto.ParticipantResponseDto;
import com.careconnect.dto.EvvRecordResponse;
import com.careconnect.model.EvvParticipant;
import com.careconnect.model.EvvRecord;

public final class EvvDtoMapper {
    private EvvDtoMapper(){}

    public static ParticipantResponseDto toDto(EvvParticipant p){
        return ParticipantResponseDto.builder()
                .id(p.getId())
                .patientName(p.getPatientName())
                .maNumber(p.getMaNumber())
                .createdAt(p.getCreatedAt())
                .createdBy(p.getCreatedBy())
                .build();
    }

    public static EvvRecordResponse toDto(EvvRecord r){
        return EvvRecordResponse.builder()
                .id(r.getId())
                .patientId(r.getPatient().getId())
                .patientMaNumber(r.getPatient().getMaNumber())
                .serviceType(r.getServiceType())
                .individualName(r.getIndividualName())
                .caregiverId(r.getCaregiverId())
                .dateOfService(r.getDateOfService())
                .timeIn(r.getTimeIn())
                .timeOut(r.getTimeOut())
                .locationLat(r.getLocationLat())
                .locationLng(r.getLocationLng())
                .locationSource(r.getLocationSource())
                .stateCode(r.getStateCode())
                .status(r.getStatus())
                .deviceInfo(r.getDeviceInfo())
                .createdAt(r.getCreatedAt())
                .updatedAt(r.getUpdatedAt())
                .build();
    }
}