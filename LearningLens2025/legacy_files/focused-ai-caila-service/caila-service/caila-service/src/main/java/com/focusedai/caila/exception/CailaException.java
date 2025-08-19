package com.focusedai.caila.exception;

import lombok.Getter;

@Getter
public class CailaException extends RuntimeException {
    private final String errorCode;
    private final Object details;
    
    public CailaException(String message) {
        super(message);
        this.errorCode = "CAILA_ERROR";
        this.details = null;
    }
    
    public CailaException(String message, String errorCode) {
        super(message);
        this.errorCode = errorCode;
        this.details = null;
    }
    
    public CailaException(String message, String errorCode, Object details) {
        super(message);
        this.errorCode = errorCode;
        this.details = details;
    }
}