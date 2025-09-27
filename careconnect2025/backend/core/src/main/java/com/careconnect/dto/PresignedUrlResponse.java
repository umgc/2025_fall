package com.careconnect.dto;

// Using a Java record for a simple, immutable DTO.
public record PresignedUrlResponse(String uploadUrl, String key) {}