package com.careconnect.util;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public abstract class JsonConverter<T> implements AttributeConverter<T, String> {

    private final ObjectMapper mapper = new ObjectMapper();
    private final TypeReference<T> typeReference;

    protected JsonConverter(TypeReference<T> typeReference) {
        this.typeReference = typeReference;
    }

    @Override
    public String convertToDatabaseColumn(T attribute) {
        try {
            return mapper.writeValueAsString(attribute);
        } catch (Exception e) {
            throw new IllegalStateException("Error writing JSON to DB", e);
        }
    }

    @Override
    public T convertToEntityAttribute(String dbData) {
        try {
            if (dbData == null) {
                return null;
            }
            return mapper.readValue(dbData, typeReference);
        } catch (Exception e) {
            throw new IllegalStateException("Error reading JSON from DB", e);
        }
    }
}


