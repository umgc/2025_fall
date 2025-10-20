package com.careconnect.dto.invoice;

public class AnalysisResult {
    public final String rawText;
    public final String s3Key;

    public AnalysisResult(String rawText, String s3Key) {
        this.rawText = rawText;
        this.s3Key = s3Key;
    }
}