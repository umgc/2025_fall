package com.careconnect.gateway;

public class AiResult {
    private String text;

    public AiResult() {}
    public AiResult(String text) { this.text = text; }

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
}
