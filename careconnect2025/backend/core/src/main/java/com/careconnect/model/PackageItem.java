package com.careconnect.model;

public record PackageItem(
        String trackingNumber,
        String expectedDateIso,
        ActionLinks actions
) {}
