package com.careconnect.model.invoice;

public record HistoryEntry(int version, String changes, String userId, String action, String details, String timestamp) {}
