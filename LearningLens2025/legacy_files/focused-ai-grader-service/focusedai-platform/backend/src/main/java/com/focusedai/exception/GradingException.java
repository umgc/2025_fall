package com.focusedai.exception;

public class GradingException extends RuntimeException {
    public GradingException(String message) {
        super(message);
    }
    
    public GradingException(String message, Throwable cause) {
        super(message, cause);
    }
}