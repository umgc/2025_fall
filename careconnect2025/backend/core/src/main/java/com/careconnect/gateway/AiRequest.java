package com.careconnect.gateway;

import java.util.Map;

public class AiRequest {

    private String provider;        // e.g. "deepseek" (default), "openai", "anthropic", "gemini"
    private String systemPrompt;    // background instructions
    private String userPrompt;      // actual task content
    private Double temperature;     // optional override
    private Integer maxTokens;      // optional override
    private Map<String, Object> extras; // extra provider-specific params

    public AiRequest() {
    }

    public AiRequest(String provider, String systemPrompt, String userPrompt,
                     Double temperature, Integer maxTokens, Map<String, Object> extras) {
        this.provider = provider;
        this.systemPrompt = systemPrompt;
        this.userPrompt = userPrompt;
        this.temperature = temperature;
        this.maxTokens = maxTokens;
        this.extras = extras;
    }

    public String getProvider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public String getSystemPrompt() {
        return systemPrompt;
    }

    public void setSystemPrompt(String systemPrompt) {
        this.systemPrompt = systemPrompt;
    }

    public String getUserPrompt() {
        return userPrompt;
    }

    public void setUserPrompt(String userPrompt) {
        this.userPrompt = userPrompt;
    }

    public Double getTemperature() {
        return temperature;
    }

    public void setTemperature(Double temperature) {
        this.temperature = temperature;
    }

    public Integer getMaxTokens() {
        return maxTokens;
    }

    public void setMaxTokens(Integer maxTokens) {
        this.maxTokens = maxTokens;
    }

    public Map<String, Object> getExtras() {
        return extras;
    }

    public void setExtras(Map<String, Object> extras) {
        this.extras = extras;
    }
}

