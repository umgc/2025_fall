package com.careconnect.dto.chat;

/**
 * @param context  Optional. The system-level instructions or context for the AI.
 * @param prompt   Required. The user's direct question or prompt.
 * @param provider Optional. The AI provider to use (e.g., "deepseek", "openai"). Defaults to "deepseek".
 */
public record AiRequest(String context, String prompt, String provider) {
    public static class AnalysisResult {
        public final String rawText;
        public final String s3Key;

        public AnalysisResult(String rawText, String s3Key) {
            this.rawText = rawText;
            this.s3Key = s3Key;
        }
    }
}