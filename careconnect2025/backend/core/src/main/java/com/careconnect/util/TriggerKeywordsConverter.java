package com.careconnect.util;

import java.util.List;

import com.careconnect.model.PatientNotetakerKeyword;
import com.fasterxml.jackson.core.type.TypeReference;

import jakarta.persistence.Converter;

@Converter
    public class TriggerKeywordsConverter extends JsonConverter<List<PatientNotetakerKeyword>> {
        public TriggerKeywordsConverter() {
            super(new TypeReference<List<PatientNotetakerKeyword>>(){});
        }
    }
